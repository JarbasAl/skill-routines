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

import re
import uuid
import datetime
from word2numberi18n import w2n
from time import sleep
from os import path, makedirs

from json_database import JsonStorage
from mycroft.skills.core import MycroftSkill, intent_file_handler
from mycroft_bus_client import Message


class RoutinesSkill(MycroftSkill):
    def __init__(self):
        super(RoutinesSkill, self).__init__(name="RoutinesSkill")
        self.routines_db_path = None
        self.routines_model = None
        self.active_routines_storage = None
        self.inactive_routines_storage = None
        self.active_routines = []
        self.inactive_routines = []
        self.scheduled_routines = []
        self.w2n_instance = None

    def initialize(self):
        self.w2n_instance = w2n.W2N(lang_param=self.lang)
        self.routines_db_path = path.join(self.file_system.path, "database")
        self.routines_model = JsonStorage(path.join(self.routines_db_path,
                                          "routines.json"))
        self.active_routines_storage = JsonStorage(path.join(self.routines_db_path,
                                                   "active_routines.json"))
        self.inactive_routines_storage = JsonStorage(path.join(self.routines_db_path,
                                                     "inactive_routines.json"))

        if not path.exists(self.routines_db_path):
            try:
                makedirs(self.routines_db_path)
            except OSError:
                self.log.error("Could not create database folder, or it already exists")

        if "routines" not in self.routines_model:
            self.routines_model["routines"] = []
            self.routines_model.store()
            
        if "routines" not in self.active_routines_storage:
            self.active_routines_storage["routines"] = []
            self.active_routines_storage.store()

        if "routines" not in self.inactive_routines_storage:
            self.inactive_routines_storage["routines"] = []
            self.inactive_routines_storage.store()
                
        # GUI Handlers
        self.gui.register_handler("routine.skill.set.routine.active", self.activate_routine)
        self.gui.register_handler("routine.skill.set.routine.inactive", self.deactivate_routine)
        self.gui.register_handler("routine.skill.edit.routine", self.edit_routine)
        self.gui.register_handler("routine.skill.save.edited.routine", self.save_edited_routine)
        self.gui.register_handler("routine.skill.delete.routine", self.remove_routine_gui)
        self.gui.register_handler("routine.skill.add.routine", self.add_routine)

        self.schedule_repeating_event(self.check_active_routines_schedule_status, datetime.datetime.now(), 300, name="check_routines")
        self.load_routines()

    def load_routines(self):
        self.active_routines = self.active_routines_storage["routines"]
        for routine in self.active_routines:
                self.setup_routine_events(routine)
                
        self.inactive_routines = self.inactive_routines_storage["routines"]
        
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
        self.routines_model["routines"].append(routine)
        self.routines_model.store()
        self.gui["routines_model"] = self.routines_model["routines"]
        self.setup_routine_events(routine)

    def activate_routine(self, message):
        routine_id = message.data["routine_id"]        
        routine = self.get_routine_by_id(routine_id)
        if routine in self.inactive_routines:
            self.inactive_routines.remove(routine)
            self.inactive_routines_storage["routines"] = self.inactive_routines
            self.inactive_routines_storage.store()

        self.setup_routine_events(routine)

    def deactivate_routine(self, message):
        routine_id = message.data["routine_id"]
        routine = self.get_routine_by_id(routine_id)
        self.active_routines.remove(routine)
        self.active_routines_storage["routines"] = self.active_routines
        self.active_routines_storage.store()
        self.inactive_routines.append(routine)
        self.inactive_routines_storage["routines"] = self.inactive_routines
        self.inactive_routines_storage.store()
        self.gui["active_routines"] = self.active_routines_storage["routines"]
        self.gui["inactive_routines"] = self.inactive_routines_storage["routines"]

        self.scheduled_routines.remove(routine_id)
        self.cancel_scheduled_event(routine_id)

    def edit_routine(self, routine_id):
        routine = self.get_routine_by_id(routine_id)
        self.gui["routine_to_edit"] = routine
        self.gui.show_page("routines_dashboard.qml")
        self.gui.send_event("routine.skill.edit.routine", routine)

    def save_edited_routine(self, message):
        edited_routine = message.data["routine"]
        routine = {
            "id": edited_routine["routine_id"],
            "name": edited_routine["routine_name"],
            "time": edited_routine["routine_time"],
            "days": edited_routine["routine_days"],
            "actions": edited_routine["routine_actions"],
            "action_sleep_time": edited_routine["routine_sleep_time"]
        }

        for i, r in enumerate(self.routines_model["routines"]):
            if r["id"] == routine["id"]:
                self.routines_model["routines"][i] = routine
                break
        self.routines_model.store()

        if routine in self.active_routines:
            self.active_routines.remove(routine)
            self.active_routines.append(routine)
            self.active_routines_storage["routines"] = self.active_routines
            self.active_routines_storage.store()
            
            if routine in self.scheduled_routines:
                self.cancel_scheduled_event(routine["id"])
                self.setup_routine_events(routine)
        
        if routine in self.inactive_routines:
            self.inactive_routines.remove(routine)
            self.inactive_routines.append(routine)
            self.inactive_routines_storage["routines"] = self.inactive_routines
            self.inactive_routines_storage.store()
    
    def remove_routine_gui(self, message):
        routine_id = message.data["routine_id"]
        self.remove_routine(routine_id)

    def remove_routine(self, routine_id):
        routine = self.get_routine_by_id(routine_id)
        if routine in self.active_routines:
            self.active_routines.remove(routine)
            self.active_routines_storage["routines"] = self.active_routines
            self.active_routines_storage.store()

            self.cancel_scheduled_event(routine_id)
            if routine_id in self.scheduled_routines:
                self.scheduled_routines.remove(routine_id)

        if routine in self.inactive_routines:
            self.inactive_routines.remove(routine)
            self.inactive_routines_storage["routines"] = self.inactive_routines
            self.inactive_routines_storage.store()
    
        self.routines_model["routines"].remove(routine)
        self.routines_model.store()
        
        self.gui["routines_model"] = self.routines_model["routines"]
        self.gui["active_routines"] = self.active_routines_storage
        self.gui["inactive_routines"] = self.inactive_routines_storage

    def setup_routine_events(self, routine):
        self.log.info("Setting up routine events")
        if routine in self.inactive_routines:
            self.inactive_routines.remove(routine)
            self.inactive_routines_storage["routines"] = self.inactive_routines
            self.inactive_routines_storage.store()
            self.gui["inactive_routines"] = self.inactive_routines_storage["routines"]
        
        if routine not in self.active_routines:
            self.active_routines.append(routine)
            self.active_routines_storage["routines"] = self.active_routines
            self.active_routines_storage.store()
            self.gui["active_routines"] = self.active_routines_storage["routines"]

        self.log.info("Setting up routine events for {}".format(routine["name"]))
        self.log.debug("Routine time: {}".format(routine["time"]))
        self.log.debug("Routine days: {}".format(routine["days"]))
                
        if self.check_if_routing_should_run_today(routine):
            datetime_pass_object = datetime.datetime.strptime(routine["time"], "%H:%M")
            
            if routine["id"] not in self.scheduled_routines:
                self.schedule_event(self.run_routine, datetime_pass_object, data=routine, name=routine["id"])
                self.scheduled_routines.append(routine["id"])
        else:
            self.log.info("Routine {} is not scheduled to run today".format(routine["id"]))
        
    def check_if_routing_should_run_today(self, routine):
        today = datetime.date.today().strftime("%A")
        captilize_today = today.capitalize()
        if captilize_today in routine["days"]:
            return True
        return False

    def run_routine(self, message):
        routine_actions = message.data.get("actions")
        if len(routine_actions) == 1:
            self.run_action(routine_actions[0])
        else:
            for action in routine_actions:
                self.run_action(action)
                sleep(message.data.get("action_sleep_time"))

    def run_action(self, action):
        self.bus.emit(Message("speak", {"utterance": action}))
        
#### Voice Interface ####

    @intent_file_handler("show.routines.dash.intent")
    def display_routines(self):
        self.gui["routines_model"] = self.routines_model["routines"]
        self.gui["active_routines"] = self.active_routines_storage
        self.gui["inactive_routines"] = self.inactive_routines_storage
        self.gui.show_page("routines_dashboard.qml", override_idle=True)

    @intent_file_handler("add.routine.intent")
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

    @intent_file_handler("delete.routine.intent")
    def remove_routine_by_voice(self, message):
        routine_name = self.get_response("routine.name.prompt", num_retries=0)
        routine = self.get_routine_by_name(routine_name)
        self.remove_routine(routine)

    def get_routine_by_name(self, routine_name):
        for routine in self.routines_model["routines"]:
            if routine["name"] == routine_name:
                return routine
        return None

    def get_routine_by_id(self, routine_id):
        for routine in self.routines_model["routines"]:
            if routine["id"] == routine_id:
                return routine
        return None

    def provide_routine_days_options(self):
        return ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    def validate_routine_name(self, utterance):
        if utterance:
            return True

    def validate_routine_days(self, utterance):
        if utterance:
            for day in self.provide_routine_days_options():
                if day in utterance:
                    return True

    def convert_time_words_to_numbers(self, utterance):
        utterance = utterance.replace("at ", "")
        
        time_regex = re.compile(r"(\d{1,2}):?(\d{2})?\s?(a\.?m\.?|p\.?m\.?|o\'?clock)?")
        time_match = time_regex.search(utterance)
        if time_match:
            hours = int(time_match.group(1))
            minutes = int(time_match.group(2)) if time_match.group(2) else 0
            am_pm = time_match.group(3)
            if am_pm:
                if am_pm == "a.m." or am_pm == "am":
                    if hours == 12:
                        hours = 0
                elif am_pm == "p.m." or am_pm == "pm":
                    if hours != 12:
                        hours += 12
            return "{:02d}:{:02d}".format(hours, minutes)

    def stop(self):
        pass

def create_skill():
    return RoutinesSkill()