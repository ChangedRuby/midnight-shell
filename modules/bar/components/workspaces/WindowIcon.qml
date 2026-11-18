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

    readonly property string appIconPath: Config.bar.workspaces.appIcons ? Icons.getAppIconPath(wmClass) : ""

    sourceComponent: appIconPath ? appIcon : glyph

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
