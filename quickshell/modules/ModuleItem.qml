// import QtQuick
// import QtQuick.Layouts

// Rectangle {
//     id: root

//     // Zorgt ervoor dat alles wat je tussen <ModuleItem> en </ModuleItem> zet,
//     // automatisch direct in de interne RowLayout terechtkomt.
//     default property alias content: contentRow.children

//     // 1. Vaste hoogte + verticale centrering voorkomt dat de pil uitsteekt aan de bovenkant
//     implicitHeight: 26
//     Layout.alignment: Qt.AlignVCenter

//     // 2. Dynamische breedte: leest de EXACTE implicitWidth van de inhoud + 16px padding
//     implicitWidth: contentRow.implicitWidth + 16

//     radius: 8

//     // Jouw exacte kleur en animatie
//     color: hoverHandler.hovered ? Qt.rgba(1, 1, 1, 0.15) : "transparent"

//     Behavior on color {
//         ColorAnimation {
//             duration: 150
//         }
//     }

//     // Vangt hover op zonder muisklikken van je modules/dropdowns te blokkeren
//     HoverHandler {
//         id: hoverHandler
//         cursorShape: Qt.PointingHandCursor

        
//     }

//     // Interne layout die de inhoud netjes centreert
//     RowLayout {
//         id: contentRow
//         anchors.centerIn: parent
//         spacing: 0
//     }
// }


import QtQuick
import QtQuick.Layouts

Item {
    id: root

    default property alias content: contentRow.children

    implicitHeight: 26
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: contentRow.implicitWidth + 16

    // Achtergrond-pil voor de hover-kleur
    Rectangle {
        anchors.fill: parent
        radius: 8
        color: hoverHandler.hovered ? Qt.rgba(1, 1, 1, 0.15) : "transparent"

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    // HoverHandler vangt enkel de hover op en laat kliks VOLLEDIG door
    HoverHandler {
        id: hoverHandler
        cursorShape: Qt.PointingHandCursor
        // Zorgt ervoor dat muiskliks niet geblokkeerd worden
        blocking: false 
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 0
    }
}
