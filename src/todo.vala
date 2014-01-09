/*
 * todo.vala
 *
 * Main application code
 *
 * @author Johannes Braun <j.braun@agentur-halma.de>
 * @package todo
 *
 */
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
		DONE,
		LINE_NR
	}

	/* Extend Granite.Application */

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

		private Task trashed_task;

		private int window_width;
		private int window_height;

		private string current_filename = null;

		/* Used for printing */
		private Gtk.PrintOperation printop;
		private Pango.Layout layout = null;
		private List<int> page_breaks = null;

		construct {
			/* Set up the app */
		 	application_id	= "todo.hannenz.de";
		 	program_name	= "Todo";
		 	app_years		= "2013";
		 	app_icon		= "todo";
		 	main_url		= "https://github.com/hannenz/todo";
		 	help_url		= "https://github.com/hannenz/todo/blob/master/README.md";
		 	bug_url			= "https://github.com/hannenz/todo/issues";

		 	about_authors	= {
					 		"Johannes Braun <me@hannenz.de>",
		 					null
		 	};
		 	about_comments	= _("Todo.txt client for elementary OS");
		 	about_license_type = Gtk.License.GPL_3_0;

		 	trashed_task = null;
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
			settings.changed["show-completed"].connect( toggle_show_completed);
			settings.changed["show-statusbar"].connect( (key) => {
				if (settings.get_boolean(key)){
					window.statusbar.show();
				}
				else {
					window.statusbar.hide();
				}
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

			/* On window resize save current size for next time */
			window.configure_event.connect ( () => {

				window.get_size(out window_width, out window_height);
				return false;

			});

			window.resize(
				settings.get_int("saved-state-width"),
				settings.get_int("saved-state-height")
			);

			/* Create and setup the data model, which
			 * stores the tasks*/
			tasks_list_store = new ListStore (6, typeof (string), typeof(string), typeof(GLib.Object), typeof(bool), typeof(bool), typeof(int));
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
			window.open_button.clicked.connect(open_file);
			window.add_button.clicked.connect(add_task);
			window.print_button.clicked.connect(print_todo_list);

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

/*
			window.delete_event.connect( (win) => {
				window.hide();
				return true;
			});
*/
			window.destroy.connect( () => {
				settings.set_int("saved-state-width", window_width);
				settings.set_int("saved-state-height", window_height);
				Gtk.main_quit();

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
				tasks_model_filter.refilter();
			});

			if (read_file(null)){
				window.welcome.hide();
				window.tree_view.show();
			}
			else {
				window.welcome.show();
				window.tree_view.hide();
			}
			tasks_model_filter.refilter();

			if (settings.get_boolean("show-statusbar") == false){
				window.statusbar.hide();
			}
		}

		protected override void open (File[] files, string hint){
			activate();
			foreach (File file in files){
				print ("Opening file: %s\n", file.get_path());
				read_file(file.get_path());
			}
		}

		private void toggle_show_completed(){

			Granite.Widgets.SourceList.Item selected_item = window.sidebar.selected;

			tasks_model_filter.refilter();
			update_global_tags();

		}

		private void setup_menus () {
			
			var accel_group = new Gtk.AccelGroup();

			var menu = new Gtk.Menu();
			var show_completed_menu_item = new Gtk.CheckMenuItem.with_label("Show Completed");
			show_completed_menu_item.add_accelerator("activate", accel_group, Gdk.Key.F3, 0, Gtk.AccelFlags.VISIBLE);
			show_completed_menu_item.activate.connect( () => {
				bool sc = settings.get_boolean("show-completed");
				sc = !sc;
				settings.set_boolean("show-completed", sc);
				// toggle_show_completed gets called automatically since it is connected to the change-signal
			});
			var show_statusbar_menu_item = new Gtk.CheckMenuItem.with_label("Statusbar");
			show_statusbar_menu_item.activate.connect ( () => {
				bool s = settings.get_boolean("show-statusbar");
				settings.set_boolean("show-statusbar", !s);
				if (!s){
					window.statusbar.show();
				}
				else {
					window.statusbar.hide();
				}

			});

			menu.append(show_completed_menu_item);
			menu.append(show_statusbar_menu_item);

			var main_menu = this.create_appmenu(menu);
			main_menu.margin_left = 12;
			window.toolbar.insert (main_menu, -1);

			window.open_button.add_accelerator("clicked", accel_group, Gdk.Key.O, Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
			window.add_button.add_accelerator("clicked", accel_group, Gdk.Key.N, Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
			window.print_button.add_accelerator("clicked", accel_group, Gdk.Key.P, Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

			window.add_accel_group(accel_group);
			menu.set_accel_group(accel_group);
			main_menu.show_all();

			popup_menu = new Gtk.Menu();
			var accel_group_popup = new Gtk.AccelGroup();
			window.add_accel_group(accel_group_popup);
			popup_menu.set_accel_group(accel_group_popup);
			var edit_task_menu_item = new Gtk.MenuItem.with_label(_("Edit task"));
			var delete_task_menu_item = new Gtk.MenuItem.with_label(_("Delete task"));
			var toggle_done_menu_item = new Gtk.MenuItem.with_label(_("Toggle done"));

			var priority_menu = new Gtk.Menu();

			var priority_menu_item = new Gtk.MenuItem.with_label(_("Priority"));
			priority_menu_item.set_submenu(priority_menu);

			var priority_none_menu_item = new Gtk.MenuItem.with_label(_("None"));
			priority_menu.append(priority_none_menu_item);
			priority_none_menu_item.add_accelerator("activate", accel_group, Gdk.Key.BackSpace, 0, Gtk.AccelFlags.VISIBLE);
			priority_none_menu_item.activate.connect ( () => {
				Task task = get_selected_task ();
				if (task != null){
					task.priority = "";
					update_todo_file_after_task_edited (task);
				}
			});

			for (char prio = 'A'; prio <= 'F'; prio++){
				var priority_x_menu_item = new Gtk.MenuItem.with_label("%c".printf(prio));
				priority_x_menu_item.add_accelerator("activate", accel_group, Gdk.Key.A + (prio - 'A'), 0, Gtk.AccelFlags.VISIBLE);
				priority_x_menu_item.activate.connect( (menu_item) => {

					Task task = get_selected_task();
					if (task != null){
						task.priority = menu_item.get_label ();
						update_todo_file_after_task_edited (task);
					}
				});
				priority_menu.append(priority_x_menu_item);
			}

			edit_task_menu_item.add_accelerator("activate", accel_group, Gdk.Key.F2, 0, Gtk.AccelFlags.VISIBLE);
			delete_task_menu_item.add_accelerator("activate", accel_group, Gdk.Key.Delete, 0, Gtk.AccelFlags.VISIBLE);
			toggle_done_menu_item.add_accelerator("activate", accel_group, Gdk.Key.space, 0, Gtk.AccelFlags.VISIBLE);
			edit_task_menu_item.activate.connect(edit_task);
			delete_task_menu_item.activate.connect(delete_task);
			toggle_done_menu_item.activate.connect(toggle_done);

			window.search_entry.add_accelerator("activate", accel_group, Gdk.Key.F, Gdk.ModifierType.CONTROL_MASK, 0);
			window.search_entry.activate.connect( () => {
				window.search_entry.has_focus = true;
			});

			popup_menu.append(toggle_done_menu_item);
			popup_menu.append(priority_menu_item);
			popup_menu.append(edit_task_menu_item);
			popup_menu.append(delete_task_menu_item);

			popup_menu.show_all();
		}

		private void update_todo_file_after_task_edited (Task task){

			if (task != null){
				tasks_model_filter.refilter ();
				todo_file.lines[task.linenr - 1] = task.to_string ();
				task.to_model(tasks_list_store, task.iter);
				todo_file.write_file();
			}

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

		private void open_file(){
			select_file();
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
			filter.add_pattern("*todo.txt");

			if (dialog.run() == Gtk.ResponseType.ACCEPT){

				read_file(dialog.get_filename());
				window.welcome.hide();
				window.tree_view.show();

			}
			dialog.destroy();
			return true;
		}

		private void update_global_tags(){
			var projects = new List<string>();
			var contexts = new List<string>();

			var selected_item = window.sidebar.selected;

			window.projects_category.clear();
			window.contexts_category.clear();

			bool show_completed = settings.get_boolean("show-completed");

			tasks_list_store.foreach( (model, path, iter) => {


				Task task;
				model.get(iter, Columns.TASK_OBJECT, out task, -1);

				if (!show_completed && task.done){
					return false;
				}

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
					if (!show_completed && task.done){
						return false;
					}
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
					if (!show_completed && task.done){
						return false;
					}
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


			bool flag = false;
			foreach (Granite.Widgets.SourceList.Item item in window.projects_category.children){
				if (item.name == selected_item.name){
					flag = true;
					window.sidebar.selected = item;
					break;
				}
			}
			if (!flag){
				foreach (Granite.Widgets.SourceList.Item item in window.contexts_category.children){
					if (item.name == selected_item.name){
						flag = true;
						window.sidebar.selected = item;
						break;
					}
				}
			}

/*			print ("Reselecting item: %s\n", selected.name);
			window.sidebar.selected = selected;
*/		}


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
			TreeModel model;
			Task task = null;
			var sel = window.tree_view.get_selection();
			if (sel.get_selected(out model, out iter)){
				model.get(iter, Columns.TASK_OBJECT, out task, -1);
			}
			return task;
		}

		private TaskDialog add_edit_dialog () {
			var dialog = new TaskDialog();

			foreach (Granite.Widgets.SourceList.Item item in window.projects_category.children){
				dialog.add_project_button(item.name);
			}
			foreach (Granite.Widgets.SourceList.Item item in window.contexts_category.children){
				dialog.add_context_button(item.name);
			}
			return dialog;
		}

		private void toggle_done () {
			Task task = get_selected_task ();
			if (task != null) {

				task.done = !task.done;
				task.to_model(tasks_list_store, task.iter);
				tasks_model_filter.refilter();
				todo_file.lines[task.linenr - 1] = task.to_string();
				todo_file.write_file();

				update_global_tags();
			}
		}

		private void edit_task () {
			TreeIter iter;
			TreeModel model;
			Task task;
			var sel = window.tree_view.get_selection();
			if (!sel.get_selected(out model, out iter)){
				return;
			}
			model.get(iter, Columns.TASK_OBJECT, out task, -1);

			if (task != null){

				var dialog = add_edit_dialog();

				dialog.entry.set_text(task.to_string());

				dialog.show_all();
				int response = dialog.run();
				switch (response){
					case Gtk.ResponseType.ACCEPT:
						task.parse_from_string(dialog.entry.get_text());
						task.to_model(tasks_list_store, task.iter);
						tasks_model_filter.refilter();
						todo_file.lines[task.linenr - 1] = task.to_string();
						todo_file.write_file();
						break;
					default:
						break;
				}
				update_global_tags();
				dialog.destroy();

				sel.select_iter(iter);
			}
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

						TreeIter iter, fiter, siter;

						tasks_list_store.append(out iter);
						task.to_model(tasks_list_store, iter);

						//tasks_model_filter.refilter();
						if (todo_file.write_file()){
							task.linenr = todo_file.n_lines;
							task.to_model(tasks_list_store, iter);
						}
						else {
							warning ("Failed to write file");
						}

						update_global_tags();

						tasks_model_filter.convert_child_iter_to_iter(out fiter, iter);
						tasks_model_sort.convert_child_iter_to_iter(out siter, fiter);

						window.tree_view.get_selection().select_iter(siter);
					}

					break;
				default:
					break;
			}
			dialog.destroy();

		}

		private void delete_task () {

			Task task = get_selected_task ();
			
			if (task != null) {

				trashed_task = task;

				todo_file.lines.remove_at (task.linenr -1);
				todo_file.write_file ();
				tasks_list_store.remove (task.iter);

				var info_bar = new Gtk.InfoBar.with_buttons(Gtk.Stock.UNDO, Gtk.ResponseType.ACCEPT);
				info_bar.set_message_type(Gtk.MessageType.INFO);
				var content = info_bar.get_content_area();
				content.add(new Label(_("The task has been deleted")));
				info_bar.show_all();

				window.info_bar_box.foreach( (child) => {
					child.destroy();
				});

				window.info_bar_box.pack_start(info_bar, true, true, 0);
				info_bar.response.connect( () => {
					undelete();
					info_bar.destroy();
				});

				update_global_tags();
			}
		}

		private void undelete () {

			if (trashed_task != null){
				print ("Restoring task: " + trashed_task.text + " at line nr. " + "%u".printf(trashed_task.linenr));

				todo_file.lines.insert(trashed_task.linenr - 1, trashed_task.to_string());
				todo_file.write_file();
				TreeIter iter;
				tasks_list_store.append(out iter);
				trashed_task.to_model(tasks_list_store, iter);
				tasks_model_filter.refilter();

				trashed_task = null;
			}
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
					Environment.get_home_dir() + DS + "bin" + DS + "todo.txt" + DS + "todo.txt",
					Environment.get_home_dir() + DS + "Dropbox" + DS + "todo.txt",
					Environment.get_home_dir() + DS + "Dropbox" + DS + "todo" + DS + "todo.txt"
				};

				todo_file = null;
				foreach (string path in paths){

					var test_file = new TodoFile(path);
					if (test_file.exists()){
						todo_file = test_file;
//						window.title = "Todo (%s)".printf (path);
						window.statusbar.push(1, path);
						break;
					}
				}
			}

			if (todo_file == null){
				// Switch to welcome mode!
				return false;
			}

			this.current_filename = filename;

			todo_file.monitor.changed.connect( (file, other_file, event) => {

				if (event == FileMonitorEvent.CHANGES_DONE_HINT){
					var info_bar = new Gtk.InfoBar.with_buttons(Gtk.Stock.OK, Gtk.ResponseType.ACCEPT);
					info_bar.set_message_type(Gtk.MessageType.WARNING);
					var content = info_bar.get_content_area();
					content.add(new Label(_("The todo.txt file has been modified and been re-read")));
					info_bar.show_all();
					window.info_bar_box.foreach( (widget) => {
						widget.destroy();
					});
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

		protected void print_todo_list () {

			printop = new Gtk.PrintOperation();

			var paper_size = new Gtk.PaperSize(Gtk.PAPER_NAME_A4);
			var setup = new Gtk.PageSetup();
			setup.set_paper_size(paper_size);

			printop.set_default_page_setup(setup);
			printop.set_unit(Gtk.Unit.MM);

			printop.begin_print.connect(this.on_begin_print);
			printop.draw_page.connect(this.on_draw_page);
			printop.end_print.connect(this.on_end_print);

			try {
				printop.run(Gtk.PrintOperationAction.PRINT_DIALOG, window);
			}
			catch (Error e) {
				warning("%s", e.message);
			}
		}

		protected void on_begin_print(PrintContext context) {

			string text = "";
			bool show_completed = settings.get_boolean("show-completed");

			tasks_list_store.foreach( (model, path, iter) => {
				Task task;
				model.get(iter, Columns.TASK_OBJECT, out task, -1);

				if (!show_completed && task.done){
					return false;
				}

				text += task.to_markup();
				text += "\n";

				return false;
			});

			double width = context.get_width();
			double height = context.get_height();

			layout = context.create_pango_layout();
			layout.set_font_description(Pango.FontDescription.from_string("Sans 22"));
			layout.set_width((int)(width * Pango.SCALE));
			layout.set_markup(text, -1);

			int num_lines = layout.get_line_count();
			page_breaks = new List<int>();
			double page_height = 0;

			Pango.Rectangle ink_rect, logical_rect;

			for (int line = 0; line < num_lines; line++) {
				Pango.LayoutLine layout_line = layout.get_line(line);
				layout_line.get_extents(out ink_rect, out logical_rect);

				double line_height = logical_rect.height / 1024.0;
				page_height += line_height;

				if (page_height + line_height > height) {
					page_breaks.append(line);
					page_height = 0;
					page_height += line_height;
				}
			}

			int n_pages = (int)page_breaks.length() + 1;
			printop.set_n_pages(n_pages);
		}

		protected void on_draw_page(PrintContext context, int page_nr) {

			int start = 0, end, i = 0;
			double start_pos = 0;

			if (page_nr != 0){
				start = page_breaks.nth_data(page_nr - 1);
			}
			if (page_nr < page_breaks.length()) {
				end = page_breaks.nth_data(page_nr);
			}
			else {
				end = layout.get_line_count();
			}

			Cairo.Context cr = context.get_cairo_context();
			cr.set_source_rgb(0, 0, 0);

			Pango.LayoutIter iter = layout.get_iter();

			while (true) {
				if (i >= start){
					
					Pango.LayoutLine line = iter.get_line_readonly();

					Pango.Rectangle ink_rect, logical_rect;
					iter.get_line_extents(out ink_rect, out logical_rect);
					int baseline = iter.get_baseline();
					if (i == start){
						start_pos = logical_rect.y / 1024.0;
					}
					cr.move_to(logical_rect.x / 1024.0, baseline / 1024.0 - start_pos);
					
					Pango.cairo_show_layout_line(cr, line);
				}
				i++;
				if (i >= end || iter.next_line() == false) {
					break;
				}
			}
		}

		protected void on_end_print(PrintContext context) {

			window.statusbar.push(0, _("Printing has been finished"));
			layout.unref();
			
		}
	}
}
