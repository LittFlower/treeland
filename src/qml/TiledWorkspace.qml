// Copyright (C) 2023 JiDe Zhang <zccrs@live.com>.
// SPDX-License-Identifier: Apache-2.0 OR LGPL-3.0-only OR GPL-2.0-only OR GPL-3.0-only

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Waylib.Server
import Treeland

Item {
    id: root
    function getSurfaceItemFromWaylandSurface(surface) {
        let finder = function(props) {
            if (!props.waylandSurface)
                return false
            // surface is WToplevelSurface or WSurfce
            if (props.waylandSurface === surface || props.waylandSurface.surface === surface)
                return true
        }

        let toplevel = Helper.xdgShellCreator.getIf(toplevelComponent, finder)
        if (toplevel) {
            return {
                shell: toplevel,
                item: toplevel,
                type: "toplevel"
            }
        }

        // let popup = Helper.xdgShellCreator.getIf(popupComponent, finder)
        // if (popup) {
        //     return {
        //         shell: popup,
        //         item: popup.xdgSurface,
        //         type: "popup"
        //     }
        // }

        let layer = Helper.layerShellCreator.getIf(layerComponent, finder)
        if (layer) {
            return {
                shell: layer,
                item: layer.surfaceItem,
                type: "layer"
            }
        }

        // let xwayland = Helper.xwaylandCreator.getIf(xwaylandComponent, finder)
        // if (xwayland) {
        //     return {
        //         shell: xwayland,
        //         item: xwayland,
        //         type: "xwayland"
        //     }
        // }

        return null
    }

    WorkspaceManager {
        id : workspaceManager
        anchors.fill: parent
    }


    SlideLayout {
        id : slideLayout
        objectName: "slideLayout"
        anchors.fill: parent
    }

    HorizontalLayout {
        id : horizontalLayout
        anchors.fill: parent
    }

    VerticalLayout {
        id : verticalLayout
        anchors.fill: parent
    }

    TallLayout {
        id : tallLayout
        anchors.fill: parent
    }

    function getPanes(wsId) {
        return workspaceManager.wsPanesById.get(wsId)
    }

    property list <XdgSurfaceItem> panes: [] // 管理所有 panes
    property list <int> paneByWs: [] // 第 i 个 pane 归属于哪个 ws
    property Item currentLayout: verticalLayout // 初始化默认布局
    property int currentWsId: -1 // currentWorkSpace id
    property int deleteFlag: -1
    property list <Item> layouts: [slideLayout, verticalLayout, horizontalLayout, tallLayout]


    Connections {
        target: Helper // sign
        function onResizePane(size, direction) {
            console.log(currentLayout)
            console.log(size, direction)
            if (currentLayout === slideLayout) {
                console.log("This Layout don't have resizePane function!")
                return
            }
            if (currentLayout === verticalLayout && (direction === 1 || direction === 2)) {
                console.log("This Layout cannot left or right anymore!")
                return
            }
            if (currentLayout === horizontalLayout && (direction === 3 || direction === 4)) {
                console.log("This Layout cannot up or down anymore!")
                return
            }
            currentLayout.resizePane(size, direction)
        }
        function onSwapPane() { currentLayout.swapPane() }
        function onRemovePane(flag) { currentLayout.removePane(flag) }
        function onChoosePane(id) { currentLayout.choosePane(id) }
        function onSwitchLayout() { switchLayout() }

        function onCreateWs() { workspaceManager.createWs() }
        function onDestoryWs() { workspaceManager.destoryWs() }
        function onSwitchNextWs() { workspaceManager.switchNextWs() }
        function onMoveWs(wsId) { --wsId; workspaceManager.moveWs(currentWsId, wsId) }
    }

    function switchLayout() {
        // console.log("switchLayout")
        let panes = workspaceManager.wsPanesById.get(currentWsId)
        let index = layouts.indexOf(currentLayout)
        let len = panes.length
        index += 1
        if (index === layouts.length) {
            index = 0
        }
        let oldLayout = currentLayout
        let tempPanes = []
        for (let i = 0; i < len; ++i) {
            tempPanes.push(panes[i])
        }
        currentLayout = layouts[index]
        for (let i = 0; i < len; ++i) {
            Helper.activatedSurface = panes[0].shellSurface
            oldLayout.removePane(0)
        }
        for (let i = 0; i < tempPanes.length; ++i) {
            currentLayout.addPane(tempPanes[i])
        }
        workspaceManager.wsLayoutById.set(currentWsId, currentLayout)
    }

        // verticalLayout

        // 创建 pane
    DynamicCreatorComponent {
        id: toplevelComponent
        creator: Helper.xdgShellCreator
        chooserRole: "type"
        chooserRoleValue: "toplevel"
        autoDestroy: false

        onObjectRemoved: function (obj) {
            obj.doDestroy()
        }

        // xdgSurface 是窗口本身
        XdgSurface {
            id: toplevelVerticalSurfaceItem
            resizeMode: SurfaceItem.SizeToSurface
            property var doDestroy: helper.doDestroy

            Component.onCompleted: {
                if (currentWsId === -1) {
                    // currentWsId = 0
                    workspaceManager.createWs(currentLayout)

                }
                // console.log("aaaa")
                paneByWs.push(currentWsId)
                currentLayout.addPane(toplevelVerticalSurfaceItem)
            }

            Component.onDestruction: {
                currentLayout.relayout(toplevelVerticalSurfaceItem)
            }

            // Rectangle {
            //     id: rect1
            //     anchors.fill: toplevelVerticalSurfaceItem
            //     color: "blue"
            // }

            OutputLayoutItem {
                anchors.fill: parent
                layout: Helper.outputLayout

                onEnterOutput: function(output) {
                    waylandSurface.surface.enterOutput(output)
                    Helper.onSurfaceEnterOutput(waylandSurface, toplevelVerticalSurfaceItem, output)
                }
                onLeaveOutput: function(output) {
                    waylandSurface.surface.leaveOutput(output)
                    Helper.onSurfaceLeaveOutput(waylandSurface, toplevelVerticalSurfaceItem, output)
                }
            }

            TiledToplevelHelper {
                id: helper
                surface: toplevelVerticalSurfaceItem
                waylandSurface: toplevelVerticalSurfaceItem.waylandSurface
                creator: toplevelComponent
            }
        }
    }

    DynamicCreatorComponent {
        id: layerComponent
        creator: Helper.layerShellCreator
        autoDestroy: false

        onObjectRemoved: function (obj) {
            obj.doDestroy()
        }

        LayerSurface {
            id: layerSurface
            creator: layerComponent
        }
    }

    DynamicCreatorComponent {
        id: inputPopupComponent
        creator: Helper.inputPopupCreator

        InputPopupSurface {
            required property WaylandInputPopupSurface popupSurface

            parent: getSurfaceItemFromWaylandSurface(popupSurface.parentSurface)
            id: inputPopupSurface
            shellSurface: popupSurface
        }
    }
}
