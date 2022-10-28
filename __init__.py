# Copyright 2022, Aditya Mehra.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import datetime
import uuid
from os import path, makedirs
from time import sleep

from json_database import JsonStorage
from lingua_franca.parse import extract_datetime
from lingua_franca.time import now_local
from mycroft.skills.core import MycroftSkill, intent_handler
from mycroft_bus_client import Message


class RoutinesSkill(MycroftSkill):
    def __init__(self):
        super(RoutinesSkill, self).__init__(name="RoutinesSkill")
        self.routines_db_path = None
        self.routines = None
        self.scheduled_routines = []

    def initialize(self):
        self.routines_db_path = path.join(self.file_system.path, "database")
        makedirs(self.routines_db_path, exist_ok=True)

        self.routines = JsonStorage(path.join(self.routines_db_path, "routines.json"))

        # GUI Handlers
        self.gui.register_handler("routine.skill.set.routine.active", self.activate_routine)
        self.gui.register_handler("routine.skill.set.routine.inactive", self.deactivate_routine)
        self.gui.register_handler("routine.skill.edit.routine", self.edit_routine)
        self.gui.register_handler("routine.skill.save.edited.routine", self.save_edited_routine)
        self.gui.register_handler("routine.skill.delete.routine", self.remove_routine_gui)
        self.gui.register_handler("routine.skill.add.routine", self.add_routine)

        self.schedule_repeating_event(self.check_active_routines_schedule_status, datetime.datetime.now(), 300,
                                      name="check_routines")
        self.load_routines()

    @property
    def active_routines(self):
        return [r for rid, r in self.routines.items() if r.get("active")]

    @property
    def inactive_routines(self):
        return [r for rid, r in self.routines.items() if not r.get("active")]

    def load_routines(self):
        for routine in self.active_routines:
            self.setup_routine_events(routine)

    def check_active_routines_schedule_status(self):
        for routine in self.active_routines:
            if self.check_if_routing_should_run_today(routine):
                self.setup_routine_events(routine)

    def add_routine(self, message):
        routine_id = uuid.uuid4().hex
        routine_to_add = message.data["routine"]
        routine = {
            "id": routine_id,
            "name": routine_to_add["routine_name"],
            "time": routine_to_add["routine_time"],
            "days": routine_to_add["routine_days"],
            "actions": routine_to_add["routine_actions"],
            "action_sleep_time": routine_to_add["routine_sleep_time"]
        }
        self.routines[routine_id] = routine
        self.routines.store()
        self._update_gui()
        self.setup_routine_events(routine)

    def activate_routine(self, message):
        routine_id = message.data["routine_id"]
        self.routines[routine_id]["active"] = True
        self.routines.store()
        self.setup_routine_events(self.routines[routine_id])

    def deactivate_routine(self, message):
        routine_id = message.data["routine_id"]
        self.routines[routine_id]["active"] = False
        self.routines.store()

        self._update_gui()

        self.scheduled_routines.remove(routine_id)
        self.cancel_scheduled_event(routine_id)

    def edit_routine(self, routine_id):
        routine = self.routines[routine_id]
        self.gui["routine_to_edit"] = routine
        self.gui.show_page("routines_dashboard.qml")
        self.gui.send_event("routine.skill.edit.routine", routine)

    def save_edited_routine(self, message):
        edited_routine = message.data["routine"]
        rid = edited_routine["id"]
        self.routines[rid].update({
            "name": edited_routine["routine_name"],
            "time": edited_routine["routine_time"],
            "days": edited_routine["routine_days"],
            "actions": edited_routine["routine_actions"],
            "action_sleep_time": edited_routine["routine_sleep_time"]
        })
        self.routines.store()

        if self.routines[rid].get("active"):
            if self.routines[rid] in self.scheduled_routines:
                self.cancel_scheduled_event(rid)
            self.setup_routine_events(self.routines[rid])

    def remove_routine_gui(self, message):
        routine_id = message.data["routine_id"]
        self.remove_routine(routine_id)

    def remove_routine(self, routine_id):
        if routine_id in self.routines:
            routine = self.routines[routine_id]
            if routine.get("active"):
                self.cancel_scheduled_event(routine_id)
                if routine_id in self.scheduled_routines:
                    self.scheduled_routines.remove(routine_id)

            self.routines.pop(routine_id)
            self._update_gui()

    def _update_gui(self):
        self.gui["routines_model"] = list(self.routines.values())
        self.gui["active_routines"] = {"routines": self.active_routines}
        self.gui["inactive_routines"] = {"routines": self.inactive_routines}

    def setup_routine_events(self, routine):
        self.log.info("Setting up routine events")
        self._update_gui()

        self.log.info(f"Setting up routine events for {routine['name']}")
        self.log.debug(f"Routine time: {routine['time']}")
        self.log.debug(f"Routine days: {routine['days']}")

        if self.check_if_routing_should_run_today(routine):
            datetime_pass_object = datetime.datetime.strptime(routine["time"], "%H:%M")
            if routine["id"] not in self.scheduled_routines:
                self.schedule_event(self.run_routine, datetime_pass_object, data=routine, name=routine["id"])
                self.scheduled_routines.append(routine["id"])
        else:
            self.log.info(f"Routine {routine['id']} is not scheduled to run today")

    @staticmethod
    def check_if_routing_should_run_today(routine):
        today = now_local().date().strftime("%A")
        if today.capitalize() in routine["days"]:
            return True
        return False

    def run_routine(self, message):
        routine_actions = message.data.get("actions")
        if len(routine_actions) == 1:
            self.run_action(routine_actions[0])
        else:
            for action in routine_actions:
                self.run_action(action)
                sleep(message.data.get("action_sleep_time", 3))

    def run_action(self, action):
        self.bus.emit(Message("recognizer_loop:utterance", {"utterance": action}))

    #### Voice Interface ####
    @intent_handler("show.routines.dash.intent")
    def display_routines(self):
        self._update_gui()
        self.gui.show_page("routines_dashboard.qml", override_idle=True)

    @intent_handler("add.routine.intent")
    def add_routine_by_voice(self, message):
        try:
            routine_name = self.get_response("routine.name.prompt", num_retries=0)
            routine_name_valid = self.validate_routine_name(routine_name)
        except:
            self.speak_dialog("routine.name.error")
            return

        routine_time_words = self.get_response("routine.time.prompt", num_retries=0)

        try:
            routine_time = self.convert_time_words_to_numbers(routine_time_words)
        except:
            self.speak_dialog("routine.time.error")
            return

        try:
            routine_days_list = []
            while True:
                routine_day = self.ask_selection(self.provide_routine_days_options(),
                                                 "routine.days.prompt", numeric=True)
                routine_days_valid = self.validate_routine_days(routine_day)
                if routine_days_valid:
                    routine_days_list.append(routine_day)

                if self.ask_yesno("routine.days.add.another") == "no":
                    break

        except:
            self.speak_dialog("routine.days.error")
            return

        routine_actions = []
        while True:
            action = self.get_response("routine.action.prompt", num_retries=0)
            routine_actions.append(action)
            if self.ask_yesno("routine.action.add.another") == "no":
                break

        routine_sleep_time = "10"
        routine_id = uuid.uuid4().hex
        routine = {"routine_name": routine_name,
                   "routine_time": routine_time,
                   "routine_days": routine_days_list,
                   "routine_actions": routine_actions,
                   "routine_id": routine_id,
                   "routine_sleep_time": routine_sleep_time}
        self.add_routine(Message("add.routine", {"routine": routine}))

    @intent_handler("delete.routine.intent")
    def remove_routine_by_voice(self, message):
        routine_name = self.get_response("routine.name.prompt", num_retries=0)
        routine = self.get_routine_by_name(routine_name)
        self.remove_routine(routine)

    def get_routine_by_name(self, routine_name):
        for routine in self.routines.values():
            if routine["name"] == routine_name:
                return routine
        return None

    def get_routine_by_id(self, routine_id):
        return self.routines.get(routine_id)

    @staticmethod
    def provide_routine_days_options():
        # TODO - lang support (via LF or resource utils)
        return ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    @staticmethod
    def validate_routine_name(utterance):
        if utterance:
            return True

    @staticmethod
    def validate_routine_days(utterance):
        if utterance:
            for day in RoutinesSkill.provide_routine_days_options():
                if day in utterance:
                    return True

    def convert_time_words_to_numbers(self, utterance):
        dt = extract_datetime(utterance, lang=self.lang)
        if dt:
            hours = dt[0].hour
            minutes = dt[0].minute
            return "{:02d}:{:02d}".format(hours, minutes)
        raise RuntimeError(f"Failed to extract a date from {utterance}")


def create_skill():
    return RoutinesSkill()
