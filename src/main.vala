/*
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
using Gtk;
using Td;

[CCode(cname="GETTEXT_PACKAGE")] extern const string GETTEXT_PACKAGE;

public static string _app_cmd_name;

static const OptionEntry[] entries = {
	{ "debug", 'd', 0, OptionArg.NONE, null, N_("Enable debugging"), null },
	{ null }
};

static int main(string[] args){
	int ret;

	_app_cmd_name = "todo";

	var context = new OptionContext("Todo.txt-File");
	context.add_main_entries(entries, GETTEXT_PACKAGE);
	try {
		context.parse(ref args);
	}
	catch (Error e){
		warning(e.message);
	}

	Gtk.init(ref args);

	var app = new Todo();
	ret = app.run(args);

	Gtk.main();
	return ret;
}
