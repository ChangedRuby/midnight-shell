pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

// Icon of one window in a workspace indicator: the app's real icon when
// bar.workspaces.appIcons is on and the app has one, otherwise the Material
// glyph of its category.
Loader {
    id: root

    required property string wmClass

    // Real icons must not sit under the active indicator, which tints everything
    // below it with a single colour. Workspace.qml therefore draws them in a second
    // layout above the indicator (realLayer) and hides them in the first one.
    // Both layouts hold every icon so they keep the same size; only one is visible.
    property bool separateRealLayer: false
    property bool realLayer: false

    readonly property string appIconPath: Config.bar.workspaces.appIcons ? Icons.getAppIconPath(wmClass) : ""
    readonly property bool isReal: appIconPath !== ""

    // Only the layer that shows the icon loads it; the other one just keeps its size.
    readonly property bool showsRealIcon: isReal && (!separateRealLayer || realLayer)

    opacity: !separateRealLayer || isReal === realLayer ? 1 : 0
    sourceComponent: showsRealIcon ? appIcon : isReal ? spacer : glyph

    Component {
        id: glyph

        MaterialIcon {
            grade: 0
            text: Icons.getAppCategoryIcon(root.wmClass, "terminal")
            color: Colours.palette.m3onSurfaceVariant
        }
    }

    Component {
        id: appIcon

        IconImage {
            // Synchronous on purpose: asynchronous loads run KIconLoader on Qt's pixmap
            // reader thread, which is not thread safe and segfaults when the GUI thread
            // loads the same icon at the same time (for example when a window of an app
            // with that icon opens, like Nexus does with org.quickshell).
            asynchronous: false
            source: root.appIconPath
            // Same size as the glyph it replaces, so the indicator does not resize.
            implicitSize: probe.implicitHeight

            MaterialIcon {
                id: probe

                visible: false
                grade: 0
                text: "terminal"
            }
        }
    }

    // Takes the place of the icon in the layer where it is hidden.
    Component {
        id: spacer

        Item {
            implicitWidth: probe.implicitHeight
            implicitHeight: probe.implicitHeight

            MaterialIcon {
                id: probe

                visible: false
                grade: 0
                text: "terminal"
            }
        }
    }
}
