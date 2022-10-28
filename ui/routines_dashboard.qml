// Copyright 2022, Aditya Mehra.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.


import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import org.kde.kirigami 2.11 as Kirigami
import Mycroft 1.0 as Mycroft
import QtGraphicalEffects 1.0

Mycroft.Delegate {
    id: root
    property var routinesDashboardModel: sessionData.routines_model
    property var activeRoutines: sessionData.active_routines.routines
    property var inactiveRoutines: sessionData.inactive_routines.routines
    leftPadding: Mycroft.Units.gridUnit * 2
    rightPadding: Mycroft.Units.gridUnit * 2
    topPadding: Mycroft.Units.gridUnit * 2
    bottomPadding: Mycroft.Units.gridUnit * 2

    
    function check_if_routine_id_in_active(routineId) {
        for (var i = 0; i < activeRoutines.length; i++) {
            if (activeRoutines[i].id === routineId) {
                return true
            }
        }
        return false
    }

    function check_if_routine_id_in_inactive(routineId) {
        for (var i = 0; i < inactiveRoutines.length; i++) {
            if (inactiveRoutines[i].id === routineId) {
                return true
            }
        }
        return false
    }

    background: Rectangle {
        color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.95)
        
        Image {
            anchors.fill: parent
            source: Qt.resolvedUrl("images/bg.png")
            fillMode: Image.PreserveAspectCrop

            ColorOverlay {
                anchors.fill: parent
                source: parent
                color: Kirigami.Theme.backgroundColor
            }
        }

        Rectangle {
            anchors.fill: parent
            Kirigami.Theme.colorSet: Kirigami.Theme.View 
            Kirigami.Theme.inherit: false
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
        }
    }

    Rectangle {
        id: addRoutineDialog        
        anchors.fill: parent
        color: Kirigami.Theme.backgroundColor
        property bool opened: false
        visible: opened
        enabled: opened
        z: 6

        function open() {
            opened = true
            visible = true
            enabled = true
        }

        function close() {
            opened = false
            visible = false
            enabled = false
        }

        Item { 
            anchors.fill: parent            
            anchors.margins: Mycroft.Units.gridUnit / 2

            Rectangle {
                id: toprAreaAddRoutineDialog
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: Mycroft.Units.gridUnit * 4
                color: Kirigami.Theme.highlightColor

                Label {
                    id: titleAddRoutineDialog
                    text: qsTr("Create New Routine")
                    anchors.left: parent.left
                    anchors.leftMargin: Mycroft.Units.gridUnit
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: Mycroft.Units.gridUnit * 2
                    width: parent.width - Mycroft.Units.gridUnit * 6
                    elide: Text.ElideRight
                    color: Kirigami.Theme.textColor
                }

                Button {
                    id: topAreaAddRoutineTopBarButton
                    anchors.right: parent.right
                    anchors.rightMargin: Mycroft.Units.gridUnit
                    anchors.verticalCenter: parent.verticalCenter
                    width: Mycroft.Units.gridUnit * 4
                    height: Mycroft.Units.gridUnit * 3

                    background: Rectangle {
                        id: topAreaAddRoutineButtonBackground
                        color: Kirigami.Theme.backgroundColor
                        border.color: Kirigami.Theme.textColor
                        border.width: 1
                    }

                    contentItem: Item {
                        Kirigami.Icon {
                            id: topAreaAddRoutineButtonIcon
                            anchors.centerIn: parent
                            source: "arrow-left"
                            width: Mycroft.Units.gridUnit * 2
                            height: Mycroft.Units.gridUnit * 2
                        }

                        ColorOverlay {
                            anchors.fill: topAreaAddRoutineButtonIcon
                            source: topAreaAddRoutineButtonIcon
                            color: Kirigami.Theme.textColor
                        }
                    }

                    onClicked: {
                        Mycroft.SoundEffects.playClickedSound(Qt.resolvedUrl("sounds/clicked.wav"))
                        addRoutineDialog.close()
                    }

                    onPressed: {
                        topAreaAddRoutineButtonBackground.color = Kirigami.Theme.highlightColor
                    }

                    onReleased: {
                        topAreaAddRoutineButtonBackground.color = Kirigami.Theme.backgroundColor
                    }
                }
            }


            ScrollBar {
                id: flickableScroller
                anchors.right: parent.right
                anchors.top: toprAreaAddRoutineDialog.bottom
                anchors.topMargin: Mycroft.Units.gridUnit / 2
                anchors.bottom: parent.bottom
                width: Mycroft.Units.gridUnit * 2
                policy: ScrollBar.AlwaysOn

                background: Rectangle {
                    color: "transparent"
                }

                contentItem: Rectangle {
                    color: Kirigami.Theme.highlightColor
                    radius: Mycroft.Units.gridUnit / 2
                }
            }

            Flickable {
                id: formFlickable
                anchors.left: parent.left
                anchors.right: flickableScroller.left
                anchors.top: toprAreaAddRoutineDialog.bottom
                anchors.topMargin: Mycroft.Units.gridUnit / 2
                anchors.bottom: parent.bottom
                ScrollBar.vertical: flickableScroller

                contentWidth: width
                contentHeight: formLayout.implicitHeight
                clip: true

                ColumnLayout {
                    id: formLayout
                    width: parent.width - (Mycroft.Units.gridUnit / 2)
                    spacing: Mycroft.Units.gridUnit / 2


                    Label {
                        text: qsTr("Routine Name:")
                        Layout.fillWidth: true
                        font.weight: Font.DemiBold
                        font.pixelSize: Mycroft.Units.gridUnit * 1.25
                        color: Kirigami.Theme.textColor
                    }

                    TextField {
                        id: routineName
                        Layout.fillWidth: true
                        Layout.preferredHeight: Mycroft.Units.gridUnit * 3
                        placeholderText: qsTr("Enter Routine name")
                    }

                    Label {
                        text: qsTr("Routine Days:")
                        Layout.fillWidth: true
                        font.weight: Font.DemiBold
                        font.pixelSize: Mycroft.Units.gridUnit * 1.25
                        color: Kirigami.Theme.textColor
                    }

                    GridLayout {                        
                        Layout.fillWidth: true
                        Layout.preferredHeight: Mycroft.Units.gridUnit * 6
                        
                        Repeater {
                            id: routineDay
                            model: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
                            
                            delegate: CheckBox {
                                id: routineDayDelegate
                                text: modelData.substring(0, 3)
                                Layout.preferredWidth: Mycroft.Units.gridUnit * 8
                                Layout.preferredHeight: Mycroft.Units.gridUnit * 3
                                Layout.alignment: Qt.AlignHCenter
                                font.capitalization: Font.Capitalize
                                palette.windowText: Kirigami.Theme.textColor
                            }
                        }
                    }

                    Label {
                        text: qsTr("Routine Time:")
                        Layout.fillWidth: true
                        font.weight: Font.DemiBold
                        font.pixelSize: Mycroft.Units.gridUnit * 1.25
                        color: Kirigami.Theme.textColor
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        ComboBox {
                            id: routineHour
                            Layout.fillWidth: true
                            Layout.preferredHeight: Mycroft.Units.gridUnit * 3
                            model: ["00", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23"]
                        }
                        ComboBox {
                            id: routineMinute
                            Layout.fillWidth: true
                            Layout.preferredHeight: Mycroft.Units.gridUnit * 3
                            model: ["00", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31", "32", "33", "34", "35", "36", "37", "38", "39", "40", "41", "42", "43", "44", "45", "46", "47", "48", "49", "50", "51", "52", "53", "54", "55", "56", "57", "58", "59"]
                        }
                    }

                    Label {
                        text: qsTr("Routine Actions:")
                        Layout.fillWidth: true
                        font.weight: Font.DemiBold
                        font.pixelSize: Mycroft.Units.gridUnit * 1.25
                        color: Kirigami.Theme.textColor
                    }

                    TextField {
                        id: routineActions
                        Layout.fillWidth: true
                        Layout.preferredHeight: Mycroft.Units.gridUnit * 3
                        placeholderText: qsTr("Enter Routine actions, separated by commas")
                    }

                    Label {
                        text: qsTr("Routine Sleep Time:")
                        Layout.fillWidth: true
                        font.weight: Font.DemiBold
                        font.pixelSize: Mycroft.Units.gridUnit * 1.25
                        color: Kirigami.Theme.textColor
                    }

                    TextField {
                        id: routineSleepActionTime
                        Layout.fillWidth: true
                        Layout.preferredHeight: Mycroft.Units.gridUnit * 3
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                        placeholderText: qsTr("Enter sleep time between actions in seconds")
                    }

                    Button {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Mycroft.Units.gridUnit * 4
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop

                        background: Rectangle {
                            color: Qt.darker(Kirigami.Theme.backgroundColor, 0.8)
                            border.color: Kirigami.Theme.highlightColor
                            border.width: 1
                            radius: 8
                        }

                        contentItem: Item {
                            RowLayout {
                                anchors.centerIn: parent

                                Kirigami.Icon {
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: height
                                    Layout.alignment: Qt.AlignVCenter
                                    source: "list-add"
                                }

                                Kirigami.Heading {
                                    level: 2
                                    Layout.fillHeight: true          
                                    wrapMode: Text.WordWrap
                                    font.bold: true
                                    color: Kirigami.Theme.textColor
                                    text: qsTr("Create Routine")
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignLeft
                                }
                            }
                        }

                        onClicked: {
                            Mycroft.SoundEffects.playClickedSound(Qt.resolvedUrl("sounds/clicked.wav"))
                            if (routineName.text === "" || routineActions.text === "" || routineSleepActionTime.text === "") {
                                console.log("Routine name, actions and sleep action time cannot be empty")
                            } else {
                                var routine_actions = routineActions.text.split(",")
                                var routine_days_list = []
                                for (var i = 0; i < routineDay.count; i++) {
                                    if (routineDay.itemAt(i).checked) {
                                        routine_days_list.push(routineDay.itemAt(i).text)
                                    }
                                }
                                var routine = {
                                    "routine_name": routineName.text,
                                    "routine_days": routine_days_list,
                                    "routine_time": routineHour.currentText + ":" + routineMinute.currentText,
                                    "routine_actions": routine_actions,
                                    "routine_sleep_time": routineSleepActionTime.text
                                }
                                triggerGuiEvent("routine.skill.add.routine", {"routine": routine})
                                addRoutineDialog.close()
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: topBar
        height: Mycroft.Units.gridUnit * 4
        color: Kirigami.Theme.highlightColor
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        z: 4
        
        Label {
            id: topBarLabel
            text: qsTr("Routines")
            anchors.left: parent.left
            anchors.leftMargin: Mycroft.Units.gridUnit
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - Mycroft.Units.gridUnit * 6
            elide: Text.ElideRight
            font.pixelSize: Mycroft.Units.gridUnit * 2
            color: Kirigami.Theme.textColor
        }

        Button {
            id: topBarButton
            anchors.right: parent.right
            anchors.rightMargin: Mycroft.Units.gridUnit
            anchors.verticalCenter: parent.verticalCenter
            width: Mycroft.Units.gridUnit * 4
            height: Mycroft.Units.gridUnit * 3

            background: Rectangle {
                id: topBarButtonBackground
                color: Kirigami.Theme.backgroundColor
                border.color: Kirigami.Theme.textColor
                border.width: 1
            }

            contentItem: Item {
                Kirigami.Icon {
                    id: topBarButtonIcon
                    anchors.centerIn: parent
                    source: "list-add"
                    width: Mycroft.Units.gridUnit * 2
                    height: Mycroft.Units.gridUnit * 2
                }

                ColorOverlay {
                    anchors.fill: topBarButtonIcon
                    source: topBarButtonIcon
                    color: Kirigami.Theme.textColor
                }
            }

            onClicked: {
                Mycroft.SoundEffects.playClickedSound(Qt.resolvedUrl("sounds/clicked.wav"))
                addRoutineDialog.open()
            }

            onPressed: {
                topBarButtonBackground.color = Kirigami.Theme.highlightColor
            }

            onReleased: {
                topBarButtonBackground.color = Kirigami.Theme.backgroundColor
            }
        }
    }

    Item {
        id: placeholderForEmptyList
        anchors.top: topBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: routinesGridView.count === 0
        enabled: routinesGridView.count === 0

        ColumnLayout {
            height: parent.height * 0.8
            anchors.centerIn: parent

            Image {
                Layout.fillHeight: true
                Layout.preferredWidth: height
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                source: Qt.resolvedUrl("images/noroutines.svg")

                ColorOverlay {
                    anchors.fill: parent
                    source: parent
                    color: Kirigami.Theme.textColor
                }
            }

            Kirigami.Heading {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                level: 2
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("No routines found")
                font.bold: true
                color: Kirigami.Theme.textColor
            }

            Kirigami.Heading {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                level: 3
                text: qsTr("Click the add + button above to add a new routine")
                font.bold: false
                color: Kirigami.Theme.textColor
            }
            Kirigami.Heading {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                level: 3
                text: qsTr("Say 'Create a new routine' to add a new routine")
                font.bold: false
                color: Kirigami.Theme.textColor
            }
        }
    }

    Kirigami.CardsGridView {
        id: routinesGridView
        anchors.top: topBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        model: routinesDashboardModel
        maximumColumnWidth: Kirigami.Units.gridUnit * 20
        visible: routinesGridView.count != 0 ? 1 : 0
        cellHeight: Mycroft.Units.gridUnit * 23
        keyNavigationEnabled: true
        highlightFollowsCurrentItem: true

        delegate: Kirigami.AbstractCard {
            property var active: root.check_if_routine_id_in_active(model.id)
            property var inactive: root.check_if_routine_id_in_inactive(model.id)

            implicitWidth: 400
            implicitHeight: routineCardContentItem.implicitHeight + Mycroft.Units.gridUnit * 3

            background: Rectangle {
                Kirigami.Theme.colorSet: Kirigami.Theme.Button 
                Kirigami.Theme.inherit: false
                color: Kirigami.Theme.backgroundColor
                border.color: Kirigami.Theme.highlightColor
                border.width: 1
                radius: 8
            }

            contentItem: ColumnLayout {
                id: routineCardContentItem
                    
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Mycroft.Units.gridUnit * 3
                    color: Qt.darker(Kirigami.Theme.backgroundColor, 0.8)
                    border.color: Kirigami.Theme.highlightColor
                    border.width: 1
                    radius: 8

                    Label {
                        text: qsTr("Routine") + ": " + model.name
                        font.capitalization: Font.Capitalize
                        font.pixelSize: 20
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        anchors.fill: parent
                        color: Kirigami.Theme.textColor
                    }
                }                

                RowLayout {
                    Layout.alignment: Qt.AlignLeft
                    spacing: 10

                    Label {
                        text: qsTr("Active")
                        font.weight: Font.DemiBold
                        color: Kirigami.Theme.textColor
                    }

                    Switch {                       
                        checked: active
                        Layout.preferredWidth: Mycroft.Units.gridUnit * 5

                        onCheckedChanged: {
                            if (checked) {
                                Mycroft.SoundEffects.playClickedSound(Qt.resolvedUrl("sounds/clicked.wav"))
                                triggerGuiEvent("routine.skill.set.routine.active", {"routine_id": model.id})
                            } else {
                                Mycroft.SoundEffects.playClickedSound(Qt.resolvedUrl("sounds/clicked.wav"))
                                triggerGuiEvent("routine.skill.set.routine.inactive", {"routine_id": model.id})
                            }
                        }
                    }
                }

                Label {
                    text: qsTr("Scheduled Days") + ": "
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    font.weight: Font.DemiBold
                    color: Kirigami.Theme.textColor
                }

                Item {
                    Layout.fillWidth: true                    
                    Layout.preferredHeight: routineCardContentItemDaysRow.implicitHeight

                    Grid {
                        id: routineCardContentItemDaysRow
                        anchors.fill: parent
                        property var daysModel: model.days
                        columns: 5
                        spacing: 10

                        Repeater {
                            model: routineCardContentItemDaysRow.daysModel
                            delegate: Rectangle {
                                color: Qt.darker(Kirigami.Theme.backgroundColor, 0.8)
                                width: Mycroft.Units.gridUnit * 5
                                height: Mycroft.Units.gridUnit * 2
                                radius: Mycroft.Units.gridUnit / 2
                                border.color: Kirigami.Theme.highlightColor
                                border.width: 1

                                Label {
                                    text: modelData.substring(0, 3)
                                    font.capitalization: Font.Capitalize
                                    width: parent.width
                                    height: parent.height
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    wrapMode: Text.WordWrap
                                    color: Kirigami.Theme.textColor
                                    font.weight: Font.DemiBold
                                }
                            }
                        }
                    }
                }

                RowLayout{
                    Layout.fillWidth: true

                    Label {
                        text: qsTr("Scheduled Time") + ": "
                        Layout.alignment: Qt.AlignVCenter
                        color: Kirigami.Theme.textColor
                        font.weight: Font.DemiBold
                    }

                    Rectangle {
                        color: Qt.darker(Kirigami.Theme.backgroundColor, 0.8)
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: Mycroft.Units.gridUnit * 5
                        Layout.preferredHeight: Mycroft.Units.gridUnit * 2
                        radius: Mycroft.Units.gridUnit / 2
                        border.color: Kirigami.Theme.highlightColor
                        border.width: 1

                        Label {
                            text: model.time
                            font.capitalization: Font.Capitalize
                            width: parent.width
                            height: parent.height
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            wrapMode: Text.WordWrap
                            color: Kirigami.Theme.textColor
                            font.weight: Font.DemiBold
                        }
                    }
                }

                Label {
                    text: qsTr("Number Of Actions") + ": " + model.actions.length
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    color: Kirigami.Theme.textColor
                    font.weight: Font.DemiBold
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Mycroft.Units.gridUnit * 3
                    Layout.bottomMargin: Mycroft.Units.gridUnit * 0.5

                    Button {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        Layout.preferredHeight: Mycroft.Units.gridUnit * 3
                        enabled: false
                        visible: false

                        background: Rectangle {
                            color: Qt.darker(Kirigami.Theme.backgroundColor, 0.8)
                            border.color: Kirigami.Theme.highlightColor
                            border.width: 1
                            radius: 8
                        }

                        contentItem: Item {
                            RowLayout {
                                anchors.centerIn: parent

                                Kirigami.Icon {
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: height
                                    Layout.alignment: Qt.AlignVCenter
                                    source: "document-edit-symbolic"

                                    ColorOverlay {
                                        anchors.fill: parent
                                        source: parent
                                        color: Kirigami.Theme.textColor
                                    }
                                }

                                Kirigami.Heading {
                                    level: 2
                                    Layout.fillHeight: true          
                                    wrapMode: Text.WordWrap
                                    font.bold: true
                                    color: Kirigami.Theme.textColor
                                    text: qsTr("Edit")
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignLeft
                                }
                            }
                        }

                        onClicked: {
                            Mycroft.SoundEffects.playClickedSound(Qt.resolvedUrl("sounds/clicked.wav"))
                            triggerGuiEvent("routine.skill.edit.routine", model.id)
                        }
                    }

                    Button {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        Layout.preferredHeight: Mycroft.Units.gridUnit * 3

                        background: Rectangle {
                            color: Qt.darker(Kirigami.Theme.backgroundColor, 0.8)
                            border.color: Kirigami.Theme.highlightColor
                            border.width: 1
                            radius: 8
                        }

                        contentItem: Item {
                            RowLayout {
                                anchors.centerIn: parent

                                Kirigami.Icon {
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: height
                                    Layout.alignment: Qt.AlignVCenter
                                    source: "user-trash-symbolic"

                                    ColorOverlay {
                                        anchors.fill: parent
                                        source: parent
                                        color: Kirigami.Theme.textColor
                                    }
                                }

                                Kirigami.Heading {
                                    level: 2
                                    Layout.fillHeight: true          
                                    wrapMode: Text.WordWrap
                                    font.bold: true
                                    color: Kirigami.Theme.textColor
                                    text: qsTr("Delete")
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignLeft
                                }
                            }
                        }

                        onClicked: {
                            Mycroft.SoundEffects.playClickedSound(Qt.resolvedUrl("sounds/clicked.wav"))
                            triggerGuiEvent("routine.skill.delete.routine", {"routine_id": model.id})
                        }
                    }
                }
            }
        }
    }
}
