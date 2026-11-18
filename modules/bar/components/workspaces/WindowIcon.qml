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

    opacity: !separateRealLayer || isReal === realLayer ? 1 : 0
    sourceComponent: isReal ? appIcon : glyph

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
            asynchronous: true
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
}
