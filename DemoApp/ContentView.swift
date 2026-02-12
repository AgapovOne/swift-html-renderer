import HTMLParser
import HTMLRenderer
import SwiftUI

struct ContentView: View {
    @State private var selection: Selection? = .sample(.textFormatting)
    @State private var showSource = true
    @State private var customHTML = "<h1>Hello</h1>\n<p>Edit this <b>HTML</b> here</p>"

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("Examples") {
                    ForEach(Sample.allCases) { sample in
                        Text(sample.title).tag(Selection.sample(sample))
                    }
                }
                Section("Renderers") {
                    ForEach(RendererExample.allCases) { example in
                        Text(example.title).tag(Selection.renderer(example))
                    }
                }
                Section("Playground") {
                    Label("HTML Editor", systemImage: "square.and.pencil")
                        .tag(Selection.editor)
                }
            }
            .navigationTitle("Demo")
        } detail: {
            switch selection {
            case .sample(let sample):
                SampleDetailView(sample: sample, showSource: showSource)
            case .renderer(let example):
                RendererDetailView(example: example, showSource: showSource)
            case .editor:
                EditorView(html: $customHTML)
            case nil:
                Text("Select a sample")
                    .foregroundStyle(.secondary)
            }
        }
        .toolbar {
            ToolbarItem {
                Toggle("Source", isOn: $showSource)
                    .toggleStyle(.switch)
            }
        }
    }
}

// MARK: - Selection

enum Selection: Hashable {
    case sample(Sample)
    case renderer(RendererExample)
    case editor
}

// MARK: - Sample Detail

struct SampleDetailView: View {
    let sample: Sample
    let showSource: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HTMLView(html: sample.html, onLinkTap: { url in
                    print("Link tapped: \(url)")
                })

                if showSource {
                    sourceBlock(sample.html)
                }
            }
            .padding(24)
        }
        .navigationTitle(sample.title)
    }
}

// MARK: - Renderer Detail

struct RendererDetailView: View {
    let example: RendererExample
    let showSource: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                example.renderedView

                if showSource {
                    sourceBlock(example.html)
                }
            }
            .padding(24)
        }
        .navigationTitle(example.title)
    }
}

// MARK: - Editor

struct EditorView: View {
    @Binding var html: String

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading) {
                Text("HTML")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                TextEditor(text: $html)
                    .font(.system(.body, design: .monospaced))
            }
            .padding()
            .frame(maxWidth: .infinity)

            Divider()

            ScrollView {
                VStack(alignment: .leading) {
                    Text("Preview")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    HTMLView(html: html, onLinkTap: { url in
                        print("Link tapped: \(url)")
                    })
                }
                .padding()
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("HTML Editor")
    }
}

// MARK: - Helpers

@ViewBuilder
func sourceBlock(_ html: String) -> some View {
    Divider()
    Text("Source HTML")
        .font(.headline)
        .foregroundStyle(.secondary)
    Text(html)
        .font(.system(.caption, design: .monospaced))
        .textSelection(.enabled)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
}


#Preview {
    ContentView()
}
