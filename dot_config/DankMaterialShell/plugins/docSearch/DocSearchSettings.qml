// Settings surface for the Document Search plugin.
//
// PluginListItem loads this file, sets pluginService on it, and sizes the
// container from implicitHeight, which PluginSettings takes from the column it
// reparents every child Item into. So every child here has to be an Item with a
// real implicit height, and nothing may be anchored to the root.
//
// PluginSettings also supplies loadValue and saveValue, which read and write
// ~/.config/DankMaterialShell/plugin_settings.json under the "docSearch" key.

import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "docSearch"

    // Filled in by the probe below. GET /stats is the only thing that proves
    // the daemon is up and the index is populated. `dsearch version` would only
    // prove the binary exists, which says nothing about either.
    property string indexStatus: "checking..."

    function checkIndex() {
        indexStatus = "checking...";
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status !== 200) {
                root.indexStatus = xhr.status === 0 ? "nothing is answering on 127.0.0.1:43654. Start dsearch with 'dsearch serve'." : "the API answered HTTP " + xhr.status;
                return;
            }
            try {
                var s = JSON.parse(xhr.responseText);
                root.indexStatus = String(s.total_files) + " files indexed, phase " + String(s.phase) + ", last indexed " + String(s.last_index_time);
            } catch (e) {
                root.indexStatus = "the API answered with something unparseable";
            }
        };
        try {
            xhr.open("GET", "http://127.0.0.1:43654/stats");
            xhr.send();
        } catch (e2) {
            root.indexStatus = "the API could not be reached";
        }
    }

    Component.onCompleted: checkIndex()

    StyledText {
        width: parent.width
        text: "Document Search"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Searches the text inside PDF, DOCX, PPTX and EPUB files through dsearch, then opens the original document. Requires dank-doctext-sync to have extracted the text first."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    ToggleSetting {
        id: noTriggerToggle
        settingKey: "noTrigger"
        label: "Always Active"
        description: noTriggerToggle.value ? "Every launcher query also runs a document search. That is a dsearch request on almost every keystroke." : "Only search when the trigger prefix is typed. Recommended."
        defaultValue: false
    }

    StringSetting {
        visible: !noTriggerToggle.value
        settingKey: "trigger"
        label: "Trigger"
        description: "Prefix that switches the launcher into document search. Do not use a letter: triggers match with a bare startsWith, so an alphabetic prefix swallows every query beginning with it. Taken already: = ` \\ :e ! , @ ? ; and anything starting with /"
        placeholder: "#"
        defaultValue: "#"
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    SliderSetting {
        settingKey: "resultLimit"
        label: "Result Limit"
        description: "How many matches to ask dsearch for"
        defaultValue: 20
        minimum: 1
        maximum: 50
        leftIcon: "filter_list"
    }

    SliderSetting {
        settingKey: "minQueryLength"
        label: "Minimum Query Length"
        description: "Nothing is searched below this. The index matches whole words, so short fragments only produce noise."
        defaultValue: 3
        minimum: 2
        maximum: 10
        leftIcon: "text_fields"
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    ToggleSetting {
        id: snippetToggle
        settingKey: "showSnippets"
        label: "Show Matching Text"
        description: snippetToggle.value ? "Subtitles show the sentence the match was found in. Costs one extra pass over the top few files." : "Subtitles show the folder the document lives in."
        defaultValue: true
    }

    SliderSetting {
        visible: snippetToggle.value
        settingKey: "snippetBudget"
        label: "Snippet Scan Limit"
        description: "How many of the top results are read for a snippet. Higher values scan more megabytes per search."
        defaultValue: 5
        minimum: 0
        maximum: 25
        leftIcon: "short_text"
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    ToggleSetting {
        id: fuzzyToggle
        settingKey: "fuzzyFallback"
        label: "Retry With Fuzzy Matching"
        description: fuzzyToggle.value ? "When an exact search finds nothing and the query is at least five characters, try again with edit distance matching. Recovers typos, costs about 3 ms more." : "Exact matches only."
        defaultValue: true
    }

    ToggleSetting {
        id: documentsOnlyToggle
        settingKey: "documentsOnly"
        label: "Documents Only"
        description: documentsOnlyToggle.value ? "Only the PDF, DOCX, PPTX and EPUB files that dank-doctext-sync has extracted." : "Also match every text file dsearch indexes on its contents: Markdown notes, lecture transcripts, source files. Those are content the launcher cannot find any other way, which is why this is off by default."
        defaultValue: false
    }

    ToggleSetting {
        id: cliFallbackToggle
        settingKey: "cliFallback"
        label: "Fall Back To The dsearch Command"
        description: cliFallbackToggle.value ? "If the HTTP API cannot be reached, retry through the dsearch binary, which talks to the same daemon over its unix socket." : "HTTP only."
        defaultValue: true
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    Column {
        width: parent.width
        spacing: Theme.spacingS

        StyledText {
            text: "Index Status"
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Medium
            color: Theme.surfaceText
        }

        StyledText {
            width: parent.width
            text: root.indexStatus
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            wrapMode: Text.WordWrap
        }

        DankButton {
            text: "Check Again"
            iconName: "refresh"
            onClicked: root.checkIndex()
        }
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    StyledText {
        width: parent.width
        text: "Notes"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    Column {
        width: parent.width
        spacing: Theme.spacingXS
        leftPadding: Theme.spacingM
        bottomPadding: Theme.spacingL

        Repeater {
            model: ["The index matches whole words. Typing 'telom' finds nothing, 'telomere' finds seven books.", "Quoted phrases and AND / OR are not supported. Several words are treated as one OR query.", "Enter opens the original document. Tab offers the containing folder and the file path.", "Run dank-doctext-sync after adding documents, then 'dsearch index sync'."]

            StyledText {
                required property string modelData
                text: "• " + modelData
                width: parent.width - Theme.spacingM
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
            }
        }
    }
}
