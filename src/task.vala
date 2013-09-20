using Gtk;
using Td;

namespace Td {

	public class Task : GLib.Object {

		public string priority;
		public string date;
		public string completed_date;
		public string due_date;
		public List<string> projects;
		public List<string> contexts;
		public string text;
		public bool done;

		public TreeIter iter;
		public int linenr;

		construct {
			done = false;
			date = "";
			completed_date = "";
			due_date = "";
			text = "";
			priority = "";
			projects = new List<string>();
			contexts = new List<string>();
		}

		public bool parse_from_string(string s){

			MatchInfo mi;
			string match;
			string match1;
			string str = s;

			projects = new List<string>();
			contexts = new List<string>();

			try {
				var re = new Regex("@[a-zA-Z0-9-_]+");
				while (re.match(str, 0, out mi)){
					match = mi.fetch(0);
					if (match != null){
						contexts.append(match.strip());
						uint start = str.index_of(match);
						str = str.splice(start, start + match.length);
					}
				}
				re = new Regex("\\+[a-zA-Z0-9-_]+");
				while (re.match(str, 0, out mi)){
					match = mi.fetch(0);
					if (match != null){
						projects.append(match.strip());
						uint start = str.index_of(match);
						str = str.splice(start, start + match.length);
					}
				}
				re = new Regex ("^(x )?(\\(([A-Z])\\))?");
				if (re.match(str, 0, out mi)){

					match1 = mi.fetch(1);
					match = mi.fetch(3);
					if (match != null){
						priority = match;
						uint start = str.index_of(match);
						str = str.splice(start-1, start + match.length + 2);
					}

					if (match1 != null && match1 == "x "){
						done = true;
						str = str.splice(0, 2);
					}
				}

				re = new Regex ("[0-9]{4}-[0-9]{2}-[0-9]{2}");
				var n = 0;
				var dates = new List<string>();
				while (re.match(str, 0, out mi)){
					match = mi.fetch(0);
					if (match != null && n < 2){
						dates.append(match);
						uint start = str.index_of(match);
						str = str.splice(start, start+11);
					}
					if (++n == 2){
						break;
					}
				}
				uint length = dates.length();
				switch (length){
					case 1:
						date = dates.nth_data(0);
						break;
					case 2:
						date = dates.nth_data(1);
						completed_date = dates.nth_data(0);
						break;
					default:
						break;
				}

				text = str.strip();
				return (text.length > 0);
			}
			catch (Error e){
				warning("%s", e.message);
				return false;
			}
		}

		public string to_string(){
			string str = "";
			if (this.done){
				str += "x ";
			}
			if (this.priority.length > 0){
				str += "(%s)".printf(this.priority);
				str += " ";
			}
			str += this.text;
			str += " ";
			foreach (string project in this.projects){
				str += project;
				str += " ";
			}
			foreach (string context in this.contexts){
				str += context;
				str += " ";
			}
			return str;
		}

		public void to_model(Gtk.ListStore model, Gtk.TreeIter? iter){
			string ctx = "";
			foreach (string context in this.contexts){
				ctx += context;
				ctx += " ";
			}
			string prj = "";
			foreach (string project in this.projects){
				prj += project;
				prj += " ";
			}

			string markup = GLib.Markup.printf_escaped("<b>%s</b><small><i>%s %s</i></small>\n<small><i>%s</i></small>", this.text, prj, ctx, nice_date(this.date));
			if (this.done)
				markup = "<s>" + markup + "</s>";

			if (iter != null){
				this.iter = iter;
			}
			else {
				iter = this.iter;
			}
			model.set(
				iter,
				Columns.PRIORITY, this.priority,
				Columns.MARKUP, markup,
				Columns.TASK_OBJECT, this,
				Columns.VISIBLE, true,
				Columns.DONE, this.done
			);

		}

		public string nice_date(string date_string){

			return date_string;
/*			string nice = "";
			try {
				var date = new DateTime();
				date.set_parse(date_string);
				if (!date.valid()){
				//	throw new GLib.Error("Invalid date");
				}
				var now = new DateTime();
				now.set_time_t(time_t(null));

				nice = "%u".printf(now.difference(date));

			}
			catch (Error e){
				warning ("%s\n", e.message);
			}

			return nice;
*/		}
	}
}

