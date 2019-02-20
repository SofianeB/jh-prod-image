/**
 * Calysto Jupyter Notebooks Extensions
 *
 * Copyright (c) The Calysto Project
 * http://github.com/Calysto/notebook-extensions
 *
 * Released under the BSD Simplified License
 *
 **/

define(["require"], function (require) {
    function publish_notebook() {
		var base_url = document.URL.substr(0,document.URL.indexOf('/notebooks/'));

  	var user = document.URL.substr(document.URL.indexOf('/user/') + 6);
	user = user.substr(0, user.indexOf('/notebooks/'));
	// base_url = base_url.replace(/\/user\//g, "/user/tree/b2drop/");

	var path = IPython.notebook.notebook_path;
	path = path.replace(/"/g, '\\"');
	var filename = path.substr(path.lastIndexOf('/') + 1);
	path = path.substr(0, path.lastIndexOf('/'));
	console.log('/home/' + user + '/' + path + '/' + filename);
	console.log('/home/jovyan/work/' + filename);
	if (path.indexOf("b2drop") !== -1) {
	    path = path.replace("b2drop", "");
	    require(['jquery',
		 'base/js/dialog'
		], function ($, dialog) {
		    var body = $('<div/>');
		    body.append($('<h4/>').text('Your notebook is publicly available at:'));
		    var url = base_url + path.replace(/ /g, "%20") + '/b2drop/' + filename.replace(/ /g, "%20");
		    var link = $('<a target="_blank"/>').attr('href', url);
		    link.text(url);
		    body.append($('<p/>').html(link));
        body.append($('<h4/>').text('You can view it in B2DROP shared repository at:'));
        var url = 'https://b2drop.eudat.eu/apps/files/?dir=/&fileid=4953962';
        var link = $('<a target="_blank"/>').attr('href', url);
        link.text(url);
        body.append($('<p/>').html(link));
		    dialog.modal({
			title: 'Shared Notebook',
			body: body,
			buttons: {
			    'OK': {}
			}
		    });
		});
	} else {
	    require(['jquery',
		 'base/js/dialog'
		], function ($, dialog) {
		    var body = $('<div/>');
		    body.append($('<h4/>').text("You want to share this notebook?"));
		    // body.append($('<p/>').text("Copies:"));
		    //body.append($('<p/>').html($('<b/>').text("/home/jovyan/work" + path + '/' + filename)));
		    //body.append($('<p/>').text("to:"));
		    //body.append($('<p/>').html($('<b/>').text("/home/jovyan/work/b2drop/" + filename)));
		    dialog.modal({
			title: 'Share a Notebook',
			body: body,
			buttons: {
			    'Share': { class: "btn-primary",
					 click: function() {
			        function handle_output(out) {
				    if ((out.content.name === "stdout") && (out.content.text.indexOf("Ok") !== -1)) {
					var body = $('<div/>');
					body.append($('<h4/>').text('Your notebook is now publicly available at:'));
					var url = base_url + "/tree/b2drop-shared/" + filename.replace(/ /g, "%20");
					var link = $('<a target="_blank"/>').attr('href', url);
					link.text(url);
					body.append($('<p/>').html(link));
          body.append($('<h4/>').text('You can view it in B2DROP shared repository at:'));
          var url = 'https://b2drop.eudat.eu/apps/files/?dir=/&fileid=4953962';
          var link = $('<a target="_blank"/>').attr('href', url);
          link.text(url);
          body.append($('<p/>').html(link));
					dialog.modal({
					    title: 'Shared Notebook',
					    body: body,
					    buttons: {
						'OK': {}
					    }
					});
				    }
				}
			        var callbacks = { 'iopub' : {'output' : handle_output}};
				IPython.notebook.kernel.execute('%%python \n\
\n\
import os \n\
import shutil \n\
import stat \n\
import errno \n\
\n\
def publish(src, dst): \n\
    if dst.startswith("~"): \n\
        dst = os.path.expanduser(dst) \n\
    dst = os.path.abspath(dst) \n\
    # Create the path of the file if dirs do not exist: \n\
    path = os.path.dirname(os.path.abspath(dst)) \n\
    try: \n\
        os.makedirs(path) \n\
    except OSError as exc: # Python >2.5 \n\
        if exc.errno == errno.EEXIST and os.path.isdir(path): \n\
            pass \n\
        else: \n\
            raise \n\
    shutil.copyfile(src, dst) \n\
    os.chmod(dst, stat.S_IRUSR | stat.S_IWUSR | stat.S_IROTH | stat.S_IRGRP) \n\
    print("Ok") \n\
\n\
publish("/home/jovyan/work' + '/' + path + '/' + filename + '", "/home/jovyan/work/b2drop-shared/' + filename + '")',
							       callbacks, {silent: false});

				return true;
			    } // function
			}, // publish button
			    'Cancel': {}
		        } // buttons
		    }); // Dialog.modal
		}); // require
          } // if/else
    }

    var load_ipython_extension = function () {
	// Put a button on the toolbar:
	if (!IPython.toolbar) {
	    $([IPython.events]).on("app_initialized.NotebookApp",
				   add_toolbar_buttons);
	    return;
	} else {
	    add_toolbar_buttons();
	}
    };

    var add_toolbar_buttons = function () {
	Jupyter.actions.register({
	    'help'   : 'Share this notebook',
	    'icon'    : 'fa-link',
	    'handler': publish_notebook
	}, 'publish_notebook', 'publish');

	IPython.toolbar.add_buttons_group([
	    {
		'action': 'publish:publish_notebook'
	    }
	], 'publish-buttons');
    };

    return {
        load_ipython_extension : load_ipython_extension,
    };
});
