jQuery(function($) {
    $(".enterusername").click(function(event) {
        if ($(this).val() == "Enter username") {
            $(this).val("");
        }
    });

    $(".enternote").click(function(event) {
        if ($(this).val() == "Enter note") {
            $(this).val("");
        }
    });

    var id = 1;
    $(".morenotes").live("click", function(event) {
        var newid = id+1;
        $("#newnotes").append("<br />");
        $("#username_" + id).clone().appendTo("#newnotes")
            .attr("id", "username_" + newid)
            .attr("name", "username_" + newid)
            .attr("value", "Enter username");
        $("#newnotes").append("  ");
        $("#note_" + id).clone().appendTo("#newnotes")
            .attr("id", "note_" + newid)
            .attr("name", "note_" + newid)
            .attr("value", "Enter note");
        id++;
    });

    $(".usernote").live("click", function(e) {
        if ($(this).html() === "No note defined") {
            $(this).html("");
        }
    });

    var editurl = Site.currentJournal ? "/" + Site.currentJournal + "/__rpc_notes" : "/__rpc_notes";
    $(".edit").live("hover", function(e) {
        $(this).editable(editurl, {
            cancel    : 'Cancel',
            submit    : 'OK',
            width     : '10em',
            name      : 'note',
            submitdata: function (value, settings) {
                return { "userid": $(this).attr('userid'),
                    "username": $(this).attr('username')}
            },
            // update all notes for the current user on the page 
            callback : function(value, settings) {
                $(".usernote_" + $(this).attr("userid")).html(value);
            }
       });
    });
});
