function get_date_string(){
    var timer = new Date();
    var cyear = timer.getFullYear();
    var cmonth = timer.getMonth()+1;
    var cdate = timer.getDate();
    var chours = timer.getHours();
    var cminutes = timer.getMinutes();
    var cseconds = timer.getSeconds();
    var cnoon="AM";
    if (cmonth < 10){
        cmonth = "0" + cmonth;
    }

    if (chours < 10){
        chours = "0" + chours;
    }

    if (cminutes < 10){
        cminutes = "0" + cminutes;
    }
    
    if (cseconds < 10){
        cseconds = "0" + cseconds;
    }
    return cyear + '/' + cmonth + '/' + cdate + '  ' + chours + ':' + cminutes + ':' + cseconds;

}


function get_branch_list(id) {
    var d_id = id;
    $.post('/GitLabRepoBranchList/',
           {'deploy_id':d_id},
           function(json) {
                   var input_branch_html = '<select name="session_value_' + d_id + '" id="session_value_' + d_id ; 
                   var branch_ary = new Array();
                   branch_ary = json.branch_list;
                   for ( i in branch_ary )
                   {
                       input_branch_html += '"><option value="' + branch_ary[i] + '">' + branch_ary[i] +'</option>';
                   }

                   input_branch_html += '</select>';
                   $('#session_input_'+id).html(input_branch_html);
           } 
    );

}


function get_tag_list(id) {
    var d_id = id;
    $.post('/GitLabRepoTagList/',
           {'deploy_id':d_id},
           function(json) {
                   var input_tag_html = '<select name="session_value_' + d_id + '" id="session_value_' + d_id ; 
                   var branch_ary = new Array();
                   tag_ary = json.tag_list;
                   for ( i in tag_ary )
                   {
                       input_tag_html += '"><option value="' + tag_ary[i] + '">' + tag_ary[i] +'</option>';
                   }

                   input_tag_html += '</select>';
                   $('#session_input_'+id).html(input_tag_html);
           } 
    );

}


function get_commit_list(id) {
    var d_id = id;
    $.post('/GitLabRepoCommitList/',
           {'deploy_id':d_id},
           function(json) {
                   var input_commit_html = '<select name="session_value_' + d_id + '" id="session_value_' + d_id ; 
                   var commit_ary = new Array();
                   commit_ary = json.commit_list;
                   for ( i in commit_ary )
                   {
                       input_commit_html += '"><option value="' + commit_ary[i] + '">' + commit_ary[i] +'</option>';
                   }

                   input_commit_html += '</select>';
                   $('#session_input_'+id).html(input_commit_html);
           } 
    );

}


function switch_input(id){
    var d_id = id;
    var session_t = $("#session_type_" + d_id).val();
    var input_branch_html = '<select name="session_value_' + d_id + '" id="session_value_' + d_id ; 
    input_branch_html += '"><option value="master">master</option> <option value="develop">develop</option> <option value="release">release</option>';
    input_branch_html += '</select>';
    var input_tag_html = '<select name="session_value_' + d_id +'" id="session_value_' + d_id + '"> <option value="tag2">tag2</option> <option value="tag1">tag1</option></select>';
    var input_repo_html = '<select name="session_value_' + d_id +'" id="session_value_' + d_id + '"> <option value="shuju">shuju</option> <option value="pp2013">pp2013</option> </select>';
    var input_html = '';

    switch(session_t)
    {
        case 'BRANCH':
            get_branch_list(d_id);
            break
        case 'TAG':
            get_tag_list(id);
            break
        case 'COMMIT':
            get_commit_list(id);
            break
        case 'REPO':
            input_html =  input_repo_html;
            break
        default:
            input_html = input_html;
    };

    $('#session_input_'+id).html(input_html);

}


function get_confirm_msg(id){
    var d_id = id;
    return 'You are trying to send a  ' + $("#session_type_" + d_id).val() + ' [' + $("#session_value_" + d_id ).val() + '] trigger, Are you sure to do it ?';
}


function send_deploy_trigger(id){
    var d_id = id;
    $.post('/ManualDeploy/', {'deploy_id':id, trigger_type: $("#session_type_" + d_id ).val(), trigger_value: $("#session_value_" + d_id).val() },function(json) {$("#MSG").append(get_date_string() + '&nbsp;>>&nbsp;&nbsp;' + json.msg + '<br /><br />\n'); });
    $('body,html').animate({scrollTop:0},1000);
}


function send_deploy_trigger2(id){
    var d_id = id;
    $.post('/ManualDeploy2/', {'deploy_id':id},function(json) {$("#MSG").append(get_date_string() + '&nbsp;>>&nbsp;&nbsp;' + json.msg + '<br /><br />\n'); });
    $('body,html').animate({scrollTop:0},1000);
}


function openprompt(confirm_msg, callback, val1, val2){
    var arg1 = val1;
    var arg2 = val2;
    var str = confirm_msg(arg1);
    $.prompt(str,{
            buttons: { Ok: true, Cancel: false },
            focus: 1,
            submit: function(e,v,m,f){ 
                if (v == true) {
                    callback(arg2);
                }
            }
    });
}


function openprompt2(callback, val1){
    var arg1 = val1;
    var str = 'Are you sure to do it ?';
    $.prompt(str,{
            buttons: { Ok: true, Cancel: false },
            focus: 1,
            submit: function(e,v,m,f){ 
                if (v == true) {
                    callback(arg1);
                }
            }
    });
}


function get_proj_list() {
    var vcs_id = $("#vcs").val();
    if (vcs_id != 'undefined')
    {
    var input_proj_html = '';
    $.post('/GitLabProjectList/',
           {'vcs_id':vcs_id},
           function(json) {
                   input_proj_html += 'gitlab_proj  <select name="repo_d" id="repo_d" onchange="javascript:switch_proj()"'; 
                   proj_ary = json.proj_list;
                   $.each(proj_ary, function(i, n) {
                       input_proj_html += '"><option value="' + n.proj_id + '">' + n.proj_repo +'</option>';
                       if (i == 0)
                       {
                           $('#proj_id').val(n.proj_id);
                           $('#repo').val(n.proj_repo);
                       }
                   }); 

                   input_proj_html += '</select>';
                   $('#repo_s').html(input_proj_html);
           } 
    );
    } else {
        $('#repo_s').html('');
        $('#proj_id').val('');
        $('#repo').val('');
    }


}


function switch_proj() {
    var proj_id = $("#repo_d").val();
    var proj_repo =  $("#repo_d").find("option:selected").text();
    $('#proj_id').val(proj_id);
    $('#repo').val(proj_repo);
}


function switch_dtask_type() {
    var dtask_type = $("#dtask_type").val();
    var post_url = '';
    if ( dtask_type == 'group' ){
        post_url = '/DTaskGroupSelectStr/';
    } else {
        post_url = '/DTaskSelectStr/';
    }
    $.post(post_url, {'dtask_type':dtask_type},function(json) {
        $("#dtask_value").empty();
        $("#dtask_value").append(json.html_select_str);
        }
    );
}


function switch_dtaskgroup() {
    var dtaskgroup_id = $("#dtaskgroup").val();

    $.post('/DTaskSelectStr2/', {'dtaskgroup_id':dtaskgroup_id},function(json) {
        $("#dtask").empty();
        $("#dtask").append(json.html_select_str);
        }
    );

    $.post('/DTaskGroupMembersStr2/', {'dtaskgroup_id':dtaskgroup_id},function(json) {
        $("#members_str").html(json.html_members_str);
        }
    );
}


function add_dtask_to_dtaskgroup() {
    var dtaskgroup_id = $("#dtaskgroup").val();
    var dtask_id = $("#dtask").val();
    $.post('/dtaskdtgroup/add/', {'dtaskgroup_id':dtaskgroup_id, 'dtask_id':dtask_id},function(json) {
        $("#result_msg").append(get_date_string() + '&nbsp;>>&nbsp;&nbsp;' + json.result_msg + '<br /><br />\n');
        $('body,html').animate({scrollTop:0},1000);
        switch_dtaskgroup();
        }
    );

}


function del_dtask_from_dtaskgroup(dg_id, d_id) {
    var dtaskgroup_id = dg_id;
    var dtask_id = d_id;
    $.post('/dtaskdtgroup/delete/', {'dtaskgroup_id':dtaskgroup_id, 'dtask_id':dtask_id},function(json) {
        $("#result_msg").append(get_date_string() + '&nbsp;>>&nbsp;&nbsp;' + json.result_msg + '<br /><br />\n');
        $('body,html').animate({scrollTop:0},1000);
        switch_dtaskgroup();
        }
    );
}


function make_arry_to_html(d_arry) {
        var s_arry = new Array();
        s_arry = d_arry;
        var html_str = '';
        for ( i in s_arry )
        {
            html_str += s_arry[i] + '<br />\n';
        }
        return html_str;
}


function get_dtask_status(d_id) {
    var dtask_id = d_id;
    $.post('/DTaskStatus/', {'dtask_id':dtask_id},function(json) {
        $("#result_msg").html(get_date_string() + '&nbsp;>>&nbsp;&nbsp;' + json.msg + '<br />' + json.repo_status + '<br />\n');
        $('body,html').animate({scrollTop:$('#result_msg').offset().top}, 1000, 'easeOutBounce');
        //$("#result_msg").animate({scrollTop:0},1000);
        
        }
    );
}


function merge_deploy(d_id) {
    var deploy_id = d_id;
    $.post('/MergeDeploy/', {'deploy_id':deploy_id},function(json) {
        $("#MSG").html(get_date_string() + '&nbsp;>>&nbsp;&nbsp;' + json.msg + '<br />\n');
        //$('body,html').animate({scrollTop:$('#MSG').offset().top}, 500, 'easeOutBounce');
        $('body,html').animate({scrollTop:0},1000);
        
        }
    );
}
	