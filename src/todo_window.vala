using Gtk;

namespace Td {
	public class TodoWindow : Gtk.Window {

		public Gtk.Box info_bar_box;
		public Gtk.Toolbar toolbar;
		public Gtk.ToolButton open_button;
		public Gtk.ToolButton add_button;
		public Gtk.ToolButton print_button;
		public Granite.Widgets.SearchBar search_entry;
		public Granite.Widgets.SourceList sidebar;
		public Granite.Widgets.SourceList.ExpandableItem projects_category;
		public Granite.Widgets.SourceList.ExpandableItem contexts_category;
		public Granite.Widgets.Welcome welcome;
		public Gtk.TreeView tree_view;
		public Gtk.CellRendererToggle cell_renderer_toggle;
		public Gtk.Statusbar statusbar;

		construct {
			title = "Todo";
			set_default_size(600, 800);

			/* Layout and containers */
			var vbox = new Box(Gtk.Orientation.VERTICAL, 0);
			var vbox2 = new Box(Gtk.Orientation.VERTICAL, 0);
			var swin = new ScrolledWindow(null, null);
			var sidebar_paned = new Granite.Widgets.ThinPaned();

			welcome = new Granite.Widgets.Welcome("Todo", _("The elementary todo.txt app"));
			welcome.append("add", _("Add task"), _("Start a new todo.txt file by adding a task"));
			welcome.append("document-open", _("Open file"), _("Use an existing todo.txt file"));
			welcome.append("info", _("What is a todo.txt file?"), _("Learn more about todo.txt"));

			/* Create toolbar */
			toolbar = new Toolbar();
			open_button = new ToolButton.from_stock(Gtk.Stock.OPEN);
			add_button = new ToolButton.from_stock(Gtk.Stock.ADD);
			print_button = new ToolButton.from_stock(Gtk.Stock.PRINT);
			toolbar.insert(open_button, -1);
			toolbar.insert(add_button, -1);
			toolbar.insert(print_button, -1);
			var right_sep = new Gtk.SeparatorToolItem ();
			right_sep.draw = false;
			right_sep.set_expand (true);
			toolbar.insert (right_sep, -1);

			// Search Entry
			search_entry = new Granite.Widgets.SearchBar (_("Search"));
			var search_item = new Gtk.ToolItem ();
			search_item.add (search_entry);
			search_item.margin_left = 12;
			toolbar.insert (search_item, -1);

			/* Create sidebar */
			sidebar = new Granite.Widgets.SourceList();
			sidebar.set_sort_func( (a, b) => {
					return a.name > b.name ? 1 : -1;
				});
			projects_category = new Granite.Widgets.SourceList.ExpandableItem(_("Projects"));
			contexts_category = new Granite.Widgets.SourceList.ExpandableItem(_("Contexts"));
			var clear_category = new Granite.Widgets.SourceList.Item(_("All"));
			clear_category.set_data("item-name", "clear");
			projects_category.set_data("item-name", "projects");
			contexts_category.set_data("item-name", "contexts");
			sidebar.root.add(clear_category);
			sidebar.root.add(projects_category);
			sidebar.root.add(contexts_category);
			sidebar.root.expand_all();

			sidebar_paned.expand = true;
			sidebar_paned.set_position(160);
			sidebar_paned.pack1(sidebar, true, false);
			sidebar_paned.pack2(vbox2, true, true);

			tree_view = setup_tree_view();
			swin.add(tree_view);
			vbox2.pack_start(swin, true, true, 0);
			vbox2.pack_start(welcome, true, true, 0);

			vbox.pack_start(toolbar, false, false, 0);
			
			// Info Bar
			info_bar_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
			vbox.pack_start(info_bar_box, false, false, 0);

			vbox.pack_start(sidebar_paned, true, true, 0);

			statusbar = new Statusbar();
			vbox.pack_start(statusbar, false, false, 0);

			add(vbox);
			show_all();
		}

		/**
		 * setup_tree_view
		 *
		 * Setup the tree view
		 * @return void
		 */
		private TreeView setup_tree_view(){
			TreeView tv = new TreeView();
			TreeViewColumn col;


			col = new TreeViewColumn.with_attributes(_("Priority"), new Granite.Widgets.CellRendererBadge(), "text", Columns.PRIORITY);
			col.set_sort_column_id(Columns.PRIORITY);
			col.resizable = true;
			tv.append_column(col);

			col = new TreeViewColumn.with_attributes(_("Task"), new CellRendererText(), "markup", Columns.MARKUP);
			col.set_sort_column_id(Columns.MARKUP);
			col.resizable = true;
			tv.append_column(col);

			cell_renderer_toggle = new CellRendererToggle();
			cell_renderer_toggle.activatable = true;
			col = new TreeViewColumn.with_attributes(_("Done"), cell_renderer_toggle, "active", Columns.DONE);
			col.set_sort_column_id(Columns.DONE);
			col.resizable = true;
			tv.append_column(col);

			return tv;
		}

		public void reset(){
			projects_category.clear();
			contexts_category.clear();
		}
	}
}