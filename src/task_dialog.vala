/**
 * @class TaskDialog
 *
 * @author Johannes Braun <me@hannenz.de>
 * @package todo
 */

using Gtk;

namespace Td {

	public class TaskDialog : Gtk.Dialog {

		public Gtk.Entry entry;
		private Gtk.EntryCompletion completion;

		private Gtk.ListStore list_store;

		private Gtk.ButtonBox bbox1;
		private Gtk.ButtonBox bbox2;
		private Gtk.ButtonBox bbox3;

		public TaskDialog() {

			entry = new Gtk.Entry();
			var content_area = this.get_content_area();
			bbox1 = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL);
			bbox2 = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL);
			bbox3 = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL);
			
			this.set_default_size(460, -1);

			content_area.pack_start(new Label(_("Task")), false, false, 0);
			content_area.pack_start(entry, false, false, 0);
			content_area.pack_start(new Label(_("Projects")), false, false, 0);
			content_area.pack_start(bbox1, false, false, 0);
			content_area.pack_start(new Label(_("Contexts")), false, false, 0);
			content_area.pack_start(bbox2, false, false, 0);
			content_area.pack_start(new Label(_("Priority")), false, false, 0);
			content_area.pack_start(bbox3, false, false, 0);

			entry.has_focus = true;

			list_store = new Gtk.ListStore(1, typeof(string));

			completion = new Gtk.EntryCompletion();
			completion.set_model(list_store);
			completion.set_text_column(0);
			completion.match_selected.connect(on_match_selected);
			completion.set_match_func(match_func);
			entry.set_completion(completion);

			this.add_button(Gtk.Stock.CANCEL, Gtk.ResponseType.REJECT);
			this.add_button(Gtk.Stock.OK, Gtk.ResponseType.ACCEPT);
			this.set_default_response(Gtk.ResponseType.ACCEPT);

			entry.activate.connect( () => {

				this.response(Gtk.ResponseType.ACCEPT);

			});

			var button = new Button.with_label("A");
			bbox3.add(button);
			button.clicked.connect(on_priority_button_clicked);
			button = new Button.with_label("B");
			bbox3.add(button);
			button.clicked.connect(on_priority_button_clicked);
			button = new Button.with_label("C");
			bbox3.add(button);
			button.clicked.connect(on_priority_button_clicked);
			button = new Button.with_label("D");
			bbox3.add(button);
			button.clicked.connect(on_priority_button_clicked);
			button = new Button.with_label("E");
			bbox3.add(button);
			button.clicked.connect(on_priority_button_clicked);
			button = new Button.with_label("F");
			bbox3.add(button);
			button.clicked.connect(on_priority_button_clicked);
		}

		private void on_priority_button_clicked (Button button) {
			try {
				MatchInfo mi;
				Regex re = new Regex("(\\([A-Z]\\) )");
				string new_text = re.replace(this.entry.text, -1, 0, "", 0);
				this.entry.text = "(%s) %s".printf(button.label, new_text);
			}
			catch (Error e){
				warning(e.message);
			}
		}

		public void add_project_button(string button_text){

			TreeIter iter;
			list_store.append(out iter);
			list_store.set(iter, 0, "+" + button_text);

			var button = new Button();
			button.set_label("+" + button_text);
			bbox1.add(button);
			button.clicked.connect(on_button_clicked);
		}

		public void add_context_button(string button_text){

			TreeIter iter;
			list_store.append(out iter);
			list_store.set(iter, 0, "@" + button_text);

			var button = new Button();
			button.set_label("@" + button_text);
			button.clicked.connect(on_button_clicked);
			bbox2.add(button);
		}

		public void on_button_clicked(Button button){
			this.entry.set_text(
				this.entry.text + " " + button.label
			);
		}

		private bool on_match_selected(TreeModel model, TreeIter iter){

			string str;
			model.get(iter, 0, out str, -1);

			int pos = entry.cursor_position;
			var buf = entry.get_buffer();
			string text = buf.get_text();

			int start = pos;
			int end = pos;

			unichar c = 0;
			for (int i = 0; text.get_prev_char(ref start, out c); i++){
				string s = c.to_string();
				if (s == " "){
					start++;
					break;
				}
				else if (s == "+" || s == "@"){
					break;
				}
			}
			for (int i = 0; text.get_next_char(ref end, out c); i++){
				if (c.to_string() == " "){
					break;
				}
			}

			string new_str = text.splice(start, end, str);
			buf.set_text((uint8[])new_str.to_utf8());
			for (int i = 0; new_str.get_next_char(ref end, out c); i++){
				if (c.to_string() == " "){
					break;
				}
			}
			entry.set_position(end);

			return true;
		}

		public bool match_func (EntryCompletion completion, string key, TreeIter iter){

			try {
				MatchInfo mi;

				// Regex could be compiled globally in constructor ?!?
				var re = new Regex("(@|\\+[A_Za-z0-9-_]*)(?!.* )");
				if (re.match(key, 0, out mi)){

					string str;
					list_store.get(iter, 0, out str, -1);

					var re2 = new Regex(Regex.escape_string(mi.fetch(0)));
					return re2.match(str.down());
				}
			}
			catch (Error e){
				warning("%s", e.message);
			}
			return false;

		}
	}
}