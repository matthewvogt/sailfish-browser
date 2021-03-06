/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Dmitry Rozhkov <dmitry.rozhkov@jollamobile.com>
**
****************************************************************************/

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */

import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: handle

    width: Theme.itemSizeSmall
    height: width

    property string type
    property Item content

    // the moving property is updated upon dragActive change to make sure
    // that Browser:SelectionMoveStart is sent out before Browser:SelectionMove
    property bool moving
    property bool dragActive: mouseArea.drag.active

    function getJson() {
        var resolution = content.child.resolution
        var json = {
            "change": handle.type,
        }
        json[handle.type] = {
                "xPos": handle.type === "start" ? (x + width) / resolution : x / resolution,
                "yPos": y / resolution
        }
        return json
    }

    // Property binding doesn't work for content.width and content.height in qt5 -> resort to assignment
    onVisibleChanged: {
        if (visible) {
            mouseArea.drag.maximumX = content.width - handle.width
            mouseArea.drag.maximumY = content.height - handle.height
        }
    }

    onDragActiveChanged: {
        if (dragActive) {
            content.child.sendAsyncMessage("Browser:SelectionMoveStart", handle.getJson())
            moving = true
        } else {
            content.child.sendAsyncMessage("Browser:SelectionMoveEnd", handle.getJson())
            moving = false
        }
    }

    Image {
        anchors.top: parent.top
        anchors.left: type === "end" ? parent.left : undefined
        anchors.right: type === "start" ? parent.right : undefined
        source: type === "start" ? "image://theme/icon-browser-dragger-start?" + Theme.highlightBackgroundColor :
                                   "image://theme/icon-browser-dragger-end?" + Theme.highlightBackgroundColor
    }

    MouseArea {
        id: mouseArea

        width: parent.width
        height: parent.height

        anchors {
            top: parent.top
            left: type === "end" ? parent.left : undefined
            right: type === "start" ? parent.right : undefined
            leftMargin: type === "end" ? -1 * (Theme.itemSizeSmall / 2) : 0
            rightMargin: type === "start" ? -1 * (Theme.itemSizeSmall / 2) : 0
        }

        drag.target: parent
        drag.axis: Drag.XandYAxis
        drag.minimumX: 0
        drag.maximumX: content.width - handle.width
        drag.minimumY: 0
        drag.maximumY: content.height - handle.height

        onPositionChanged: {
            if (timer.running || !handle.moving) {
                return
            }

            content.child.sendAsyncMessage("Browser:SelectionMove", handle.getJson())
            timer.start()
        }
    }

    Timer {
        id: timer

        interval: 200
    }
}
