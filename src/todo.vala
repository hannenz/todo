using Gtk;
using Td;

namespace Td {

	/* Symbolic names for the columns in the
	   data model (ListStore)
	*/
	enum Columns {
		PRIORITY,
		MARKUP,
		TASK_OBJECT,
		VISIBLE,
		DONE
	}

	public class Todo : Granite.Application {

		/* All user editable stuff is in GLib.Settings (use dconf-editor to inspect) */
		public GLib.Settings settings;

		/* File stuff */
		private File file;
		private TodoFile todo_file;

		/* Widgets */
		private TodoWindow window;
		private Gtk.Menu popup_menu;

		/* Models and Lists */		
		private ListStore tasks_list_store;
		private TreeModelFilter tasks_model_filter;
		private TreeModelSort tasks_model_sort;

		/* Variables, Parameters and stuff */
		private string project_filter;
		private string context_filter;

		construct {
			/* Set up the app */
		 	application_id	= "todo.hannenz.de";
		 	program_name	= "Todo";
		 	app_years		= "2013";
		 	app_icon		= "todo";
		 	main_url		= "todo.hannenz.de";
		 	help_url		= "todo.hannenz.de/help";
		 	bug_url			= "todo.hannenz.de/bugs";

		 	about_authors	= {
					 		"Johannes Braun <me@hannenz.de",
		 					null
		 	};
		 	about_comments	= _("Todo.txt client for elementary OS");
		 	about_license_type = Gtk.License.GPL_3_0;
		}
		public Todo() {

			Intl.setlocale(LocaleCategory.MESSAGES, "");
			Intl.textdomain(GETTEXT_PACKAGE);
			Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "utf-8");

			Granite.Services.Logger.initialize("Todo");
			Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.DEBUG;

			ApplicationFlags flags = ApplicationFlags.HANDLES_OPEN;
			set_flags(flags);

		 	/* Reset tags filter */
		 	project_filter = "";
		 	context_filter = "";

		 	/* Setup / connect to GSettings */
			settings = new GLib.Settings("org.pantheon.todo");
			settings.changed["todo-txt-file-path"].connect( () => {
				/* if the path to the todo.txt file changes we want
				 * to re-read it */
				read_file(null);
			});
			settings.changed["show-completed"].connect( (key) => {
				/* If the setting for "show-completed" changes
				 * we want the treeview to be re-filtered */
				tasks_model_filter.refilter();
			});
		}


		/**
		 * activate
		 *
		 * Application startup
		 */
		public override void activate(){

			/* Create & setup the application window */
			window = new TodoWindow();

			/* Create and setup the data model, which
			 * stores the tasks*/
			tasks_list_store = new ListStore (5, typeof (string), typeof(string), typeof(GLib.Object), typeof(bool), typeof(bool));
			setup_model();
			// connect model and tree_view
			window.tree_view.set_model(tasks_model_sort);

			/* Setup menus, shortcuts and actions */
			setup_menus();

			/* Connect signals.
			 * All Callbacks are here in todo.vala - on application level. */

			/* On search_entry changed refilter the model */
			window.search_entry.text_changed_pause.connect( (query) => {
				tasks_model_filter.refilter();
			});

			/* On add button clicked, show add task dialog */
			window.add_button.clicked.connect(add_task);

			/* Detect right click on tree view columns and show popup context menu (edit/ delete) */
			window.tree_view.button_press_event.connect( (tv, event) => {
				if ((event.button == 3) && (event.type == Gdk.EventType.BUTTON_PRESS)){	// 3 = Right mouse button
					TreePath path;
					TreeIter iter;
					TreeViewColumn column;
					int cell_x;
					int cell_y;
					Task task;
					if (window.tree_view.get_path_at_pos((int)event.x, (int)event.y, out path, out column, out cell_x, out cell_y)){
						tasks_model_sort.get_iter_from_string(out iter,path.to_string());
						tasks_model_sort.get(iter, Columns.TASK_OBJECT, out task, -1);
						popup_menu.popup(null, null, null, event.button, event.time);
					}
				}
				return false;
			});
			window.tree_view.row_activated.connect(edit_task);

			window.sidebar.item_selected.connect( (item) => {

				string item_name = item.get_data("item-name");
				if (item_name == "clear"){
					context_filter = "";
					project_filter = "";
					tasks_model_filter.refilter();
				}
				else {
					item_name = item.parent.get_data("item-name");
					if (item_name == "contexts"){
						context_filter = "@"+item.name;
						project_filter = "";
						tasks_model_filter.refilter();
					}
					else if (item_name == "projects") {
						project_filter = "+"+item.name;
						context_filter = "";
						tasks_model_filter.refilter();
					}
				}
			});
			window.delete_event.connect( () => {
				Gtk.main_quit();
				return false;
			});

			window.welcome.activated.connect((index) => {
				switch (index){
					case 0:
						add_task();
						settings.set_string("todo-txt-file-path", file.get_path());
						this.window.destroy();
						// There are better ways to do this ;)
						this.activate();
						break;
					case 1:
						select_file();
						// start over
						break;
					case 2:	
						Granite.Services.System.open_uri("http://todotxt.com");
						break;
				}
			});

			window.cell_renderer_toggle.toggled.connect( (toggle, path) => {
				Task task;
				TreeIter iter;
				TreePath tree_path = new Gtk.TreePath.from_string(path);
				tasks_model_sort.get_iter(out iter, tree_path);
				tasks_model_sort.get(iter, Columns.TASK_OBJECT, out task, -1);
				task.done = (task.done ? false : true);
				task.to_model(tasks_list_store, null);
				todo_file.lines[task.linenr - 1] = task.to_string();
				todo_file.write_file();
			});

			read_file(null);
			window.welcome.hide();
			window.tree_view.show();
			tasks_model_filter.refilter();
		}

		protected override void open (File[] files, string hint){
			activate();
			foreach (File file in files){
				print ("Opening file: %s\n", file.get_path());
				read_file(file.get_path());
			}
		}

		private void setup_menus(){
			
			var accel_group = new Gtk.AccelGroup();

			var menu = new Gtk.Menu();
			var show_completed_menu_item = new Gtk.CheckMenuItem.with_label("Show Completed");
			show_completed_menu_item.add_accelerator("activate", accel_group, Gdk.Key.F3, 0, Gtk.AccelFlags.VISIBLE);
			show_completed_menu_item.activate.connect( () => {
				bool sc = settings.get_boolean("show-completed");
				sc = !sc;
				settings.set_boolean("show-completed", sc);
				tasks_model_filter.refilter();
			});

			menu.append(show_completed_menu_item);

			var main_menu = this.create_appmenu(menu);
			main_menu.margin_left = 12;
			window.toolbar.insert (main_menu, -1);

			window.add_button.add_accelerator("clicked", accel_group, Gdk.Key.N, Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

			window.add_accel_group(accel_group);
			menu.set_accel_group(accel_group);
			main_menu.show_all();

			popup_menu = new Gtk.Menu();
			var accel_group_popup = new Gtk.AccelGroup();
			window.add_accel_group(accel_group_popup);
			popup_menu.set_accel_group(accel_group_popup);
			var edit_task_menu_item = new Gtk.MenuItem.with_label(_("Edit task"));
			var delete_task_menu_item = new Gtk.MenuItem.with_label(_("Delete task"));
			edit_task_menu_item.add_accelerator("activate", accel_group, Gdk.Key.F2, 0, Gtk.AccelFlags.VISIBLE);
			delete_task_menu_item.add_accelerator("activate", accel_group, Gdk.Key.Delete, 0, Gtk.AccelFlags.VISIBLE);

			edit_task_menu_item.activate.connect(edit_task);
			delete_task_menu_item.activate.connect(delete_task);

			popup_menu.append(edit_task_menu_item);
			popup_menu.append(delete_task_menu_item);
			popup_menu.show_all();
		}


		/**
		 * reset
		 *
		 * reset the app so that the todo.txt file can be re-read
		 */
		private void reset(){
			// Close file 
			// Empty Sidebar SourceLists

			this.window.reset();
			tasks_list_store.clear();

		}

		/**
		 * setup_model
		 *
		 * Setup the necessary model, apply Filter and Sortable and setup everything
		 * @return void
		 */
		private void setup_model(){

			tasks_model_filter = new TreeModelFilter(tasks_list_store, null);
			tasks_model_filter.set_visible_func(filter_function);
			tasks_model_sort = new Gtk.TreeModelSort.with_model(tasks_model_filter);
			/* Custom sort func to sort "No priority" (empty string) after(!) any other priority */
			tasks_model_sort.set_sort_func( Columns.PRIORITY, (model, iter_a, iter_b) => {
				string prio_a;
				string prio_b;
				model.get(iter_a, Columns.PRIORITY, out prio_a, -1);
				model.get(iter_b, Columns.PRIORITY, out prio_b, -1);

				if (prio_a == "" && prio_b != ""){
					return 1;
				}
				if (prio_a != "" && prio_b == ""){
					return -1;
				}
				return (prio_a < prio_b ? -1 : 1);
			});
			tasks_model_sort.set_sort_column_id(Columns.PRIORITY, Gtk.SortType.ASCENDING);
		}

		private bool select_file(){
			var dialog = new FileChooserDialog(
				_("Select your todo.txt file"),
				this.window,
				Gtk.FileChooserAction.OPEN,
				Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
				Gtk.Stock.OPEN, Gtk.ResponseType.ACCEPT
			);

			Gtk.FileFilter filter = new FileFilter();
			dialog.set_filter(filter);
			filter.add_pattern("todo.txt");

			if (dialog.run() == Gtk.ResponseType.ACCEPT){

			}
			dialog.destroy();
			return true;
		}

		private void update_global_tags(){
			var projects = new List<string>();
			var contexts = new List<string>();

			window.projects_category.clear();
			window.contexts_category.clear();

			tasks_list_store.foreach( (model, path, iter) => {

				Task task;
				model.get(iter, Columns.TASK_OBJECT, out task, -1);

				foreach (string context in task.contexts ){
					var ctx = context.splice(0, 1);
					if(!is_in_list(contexts, ctx)){
						contexts.append(ctx);
					}
				}
				foreach (string project in task.projects){
					var prj = project.splice(0, 1);
					if(!is_in_list(projects, prj)){
						projects.append(prj);
					}
				}

				return false;

			});

			foreach (string context in contexts){
				var item = new Granite.Widgets.SourceList.Item(context);
				int count = 0;
				tasks_list_store.foreach( (model, path, iter) => {
					Task task;
					model.get(iter, Columns.TASK_OBJECT, out task, -1);
					if (is_in_list(task.contexts, "@"+context)){
						count ++;
					}
					return false;
				});
				if (count > 0)
					item.badge = "%u".printf(count);
				window.contexts_category.add(item);
			}
			foreach (string project in projects){
				var item = new Granite.Widgets.SourceList.Item(project);
				int count = 0;
				tasks_list_store.foreach( (model, path, iter) => {
					Task task;
					model.get(iter, Columns.TASK_OBJECT, out task,-1);
					if (is_in_list(task.projects, "+"+project)){
						count++;
					}
					return false;
				});
				if (count > 0){
					item.badge = "%u".printf(count);
				}
				window.projects_category.add(item);
			}
		}


		private bool filter_function(TreeModel model, TreeIter iter){

			bool ret = false;
			string query = this.window.search_entry.get_text().down();

			Task task;
			model.get(iter, Columns.TASK_OBJECT, out task, -1);

			if (task != null){

				ret = (
					(query.length == 0) ||
					(task.text.down().index_of(query) >= 0)
				);

				if (context_filter.length > 0){
					ret = (ret && is_in_list(task.contexts, context_filter));
				}
				if (project_filter.length > 0){
					ret = (ret && is_in_list(task.projects, project_filter));
				}
				var sc = settings.get_boolean("show-completed");
				if (sc == false && task.done == true){
					ret = false;
				}
			}
			return ret;
		}

		private bool is_in_list(List<string> list, string item){
			foreach (string i in list){
				if (i == item){
					return true;
				}
			}
			return false;
		}

		private Task get_selected_task(){
			TreeIter iter;
			Gtk.TreeModel model;
			Task task;
			var sel = window.tree_view.get_selection();
			sel.get_selected(out model, out iter);
			model.get(iter, Columns.TASK_OBJECT, out task, -1);
			return task;
		}

		private TaskDialog add_edit_dialog(){
			var dialog = new TaskDialog();

			foreach (Granite.Widgets.SourceList.Item item in window.projects_category.children){
				dialog.add_project_button(item.name);
			}
			foreach (Granite.Widgets.SourceList.Item item in window.contexts_category.children){
				dialog.add_context_button(item.name);
			}
			return dialog;
		}

		private void edit_task(){
			Task task = get_selected_task();

			var dialog = add_edit_dialog();
			dialog.show_all();
			int response = dialog.run();
			switch (response){
				case Gtk.ResponseType.ACCEPT:
					task.parse_from_string(dialog.entry.get_text());
					task.to_model(tasks_list_store, task.iter);
					todo_file.lines[task.linenr - 1] = task.to_string();
					todo_file.write_file();
					break;
				default:
					break;
			}
			update_global_tags();
			dialog.destroy();
		}


		private void add_task (){
			var dialog = add_edit_dialog();
			dialog.show_all ();

			int response = dialog.run ();
			switch (response){
				case Gtk.ResponseType.ACCEPT:
					string str = dialog.entry.get_text();
					Task task = new Task();
					todo_file.lines.add(str);
					if (task.parse_from_string(str)){
						TreeIter iter;
						tasks_list_store.append(out iter);
						task.to_model(tasks_list_store, iter);
						if (todo_file.write_file()){
							debug ("File has been successfully written");
						}
						else {
							debug ("Failed to write file");
						}

/*						try {
							FileOutputStream os = file.append_to(FileCreateFlags.NONE);
							os.write(task.to_string().data);
						}
						catch (Error e){
							error("Failed to write to todo.txt file: %s", e.message);
						}
*/					}
					break;
				default:
					break;
			}
			// update global projects and contexts
			update_global_tags();
			dialog.destroy();
		}

		private void delete_task () {
			Task task = get_selected_task ();
			todo_file.lines.remove_at (task.linenr -1);
			todo_file.write_file ();
			tasks_list_store.remove (task.iter);
		}

		/**
		 * read_file
		 *
		 * Read the todo.txt file
		 * 
		 * File path is read from GSettings. If setting is empty ("") we
		 * try if $HOME/todo.txt exists. If yes, we take this.
		 * As long as we dont have a setting (empty string) or the path
		 * is non-readable/ non-existent we fall-back to "welcome-state"
		 *
		 * @param filename optional filename to be opened (from command line)
		 * 
		 * @return success
		 */
		public bool read_file (string? filename) {
			/* Always restore "empty" state before (re)reading the file */
			reset();

			if (filename != null){
				todo_file = new TodoFile(filename);
			}
			else {
				string DS = "%c".printf(GLib.Path.DIR_SEPARATOR);
				string[] paths = {
					settings.get_string("todo-txt-file-path"),
					Environment.get_home_dir() + DS + "todo.txt",
					Environment.get_home_dir() + DS + "Dropbox" + DS + "todo.txt",
					Environment.get_home_dir() + DS + "Dropbox" + DS + "todo" + DS + "todo.txt"
				};

				todo_file = null;
				foreach (string path in paths){

					var test_file = new TodoFile(path);
					if (test_file.exists()){
						todo_file = test_file;
						window.title = "Todo (%s)".printf (path);
						break;
					}
				}
			}

			if (todo_file == null){
				// Switch to welcome mode!
				return false;
			}

			todo_file.monitor.changed.connect( (file, other_file, event) => {

/*				switch (event){
					case FileMonitorEvent.CHANGED:				debug ("CHANGED"); break;
					case FileMonitorEvent.CHANGES_DONE_HINT:	debug ("CHANGES_DONE_HINT"); break;
					case FileMonitorEvent.DELETED:				debug ("DELETED"); break;
					case FileMonitorEvent.CREATED:				debug ("CREATED"); break;
					case FileMonitorEvent.ATTRIBUTE_CHANGED:	debug ("ATTR CHANGED"); break;
					case FileMonitorEvent.PRE_UNMOUNT:			debug ("PRE_UNMOUNT"); break;
					case FileMonitorEvent.UNMOUNTED:			debug ("UNMOUNTED"); break;
					case FileMonitorEvent.MOVED:				debug ("MOVED"); break;
				}
*/

				if (event == FileMonitorEvent.CHANGES_DONE_HINT){
					debug ("--- The todo.txt file has been changed! ---");
					var info_bar = new Gtk.InfoBar.with_buttons(Gtk.Stock.OK, Gtk.ResponseType.ACCEPT);
					info_bar.set_message_type(Gtk.MessageType.WARNING);
					var content = info_bar.get_content_area();
					content.add(new Label(_("The todo.txt file has been modified and been re-read")));
					info_bar.show_all();
					window.info_bar_box.pack_start(info_bar, true, true, 0);
					info_bar.response.connect( () => {
						info_bar.destroy();
					});
					read_file(null);
				}
			});

			try {
				int n = todo_file.read_file();
				for (int i = 0; i < n; i++){
					var task = new Task();
					if (task.parse_from_string(todo_file.lines[i])){
						TreeIter iter;
						tasks_list_store.append(out iter);
						task.linenr = i+1;
						task.to_model(tasks_list_store, iter);
					}
				}
				update_global_tags();
			}
			catch (Error e){
				warning("%s", e.message);
				return false;
			}
			return true;
		}
	}
}