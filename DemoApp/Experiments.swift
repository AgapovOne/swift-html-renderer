import SwiftUI
import HTMLRenderer

struct Experiments: View {

    var body: some View {
        HTMLView(html: """
<p>Each <b>element</b> <i>type</i> can have a custom renderer via <code>@HTMLContentBuilder</code>.</p>
""")
    }
}


#Preview {
    Experiments()
}
