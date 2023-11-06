//
//  TemplateWidget.swift
//  TemplateWidget
//

import WidgetKit
import SwiftUI
import RctWidgetExtension

struct Provider: TimelineProvider {
    let entryViewManager: RSUIEntryViewManager

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct TemplateWidgetEntryView : View {
    var entry: Provider.Entry
    var entryViewManager: RSUIEntryViewManager
  
    var body: some View {
      entryViewManager.render()
    }
}

struct TemplateWidget: Widget {
    let kind: String = "TemplateWidget"
    let entryViewManager: RSUIEntryViewManager = RSUIEntryViewManager(
      moduleName: "RCTWidget",
      bundlePath: "Widget"
    )

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider(entryViewManager: entryViewManager)) { entry in
            TemplateWidgetEntryView(entry: entry, entryViewManager: entryViewManager)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}
