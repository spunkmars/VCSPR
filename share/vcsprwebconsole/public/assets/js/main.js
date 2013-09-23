/*
 * MeWebStudio Solutions
 * @author      : Muharrem ERİN / MeWebStudio
 * @contact     : me@mewebstudio.com
 * @copyright   : (c) 2013 MeWebStudio All rights reserved!
 *
 */

!function ($) {

	var $window = $(window);

	/* Begin: External URLs */
	$('a.ext').click(function(){
		window.open($(this).attr('href'));
		return false;
	});
	/* End: External URLs */

	$('#wrap .content').css({ minHeight: $(document).height() / 1.8 + 'px' });
	$(window).resize(function(){
		$('#wrap .content').css({ minHeight: $(document).height() / 1.8 + 'px' });
	});

	/* Begin: Header-Right Navigation */
	$('#nav-top li').each(function(){
		$(this).find('ul').css({ minWidth: $(this).width() - 22 + 'px' });
	});
	$('#nav-top li').click(function(){
		var $subnav = $(this).children('ul');
		if ($('#nav-top li ul').is(':visible'))
		{
			$('#nav-top li a').removeClass('active');
			$('#nav-top li ul').slideUp(100, 'swing');
		}
		$('#nav-top li ul a').removeClass('active');
		if ($subnav.html())
		{
			var $parentlink = $subnav.parent('li').find('a:first-child');
			if ($subnav.is(':visible'))
			{
				$parentlink.removeClass('active');
				$subnav.slideUp(100, 'swing');
			}
			else
			{
				$subnav.slideDown(400, 'easeOutBounce');
				$parentlink.addClass('active');
			}
		}
		else
		{
			document.location.href = $(this).find('a').attr('href');
		}
		return false;
	});
	$(document).click(function(){
		if ($('#nav-top li ul').is(':visible'))
		{
			$('#nav-top li a').removeClass('active');
			$('#nav-top li ul').slideUp(100, 'swing');
		}
	});
	/* End: Header-Right Navigation */

	/* Begin: Responsive Navigation */
	$('#nav-left .inline .fixed').html($('#nav-main').html()).css({ height: $(document).height() + 130 + 'px' });
	$('#nav-left ul.nav').css({ height: $(window).height() + 5 + 'px', overflow: 'auto' });
	var $navstatus = true;
	$('a.open-nav').click(function(){
		if (!$navstatus)
		{
			$(this).removeClass('open-nav-active');
			$navstatus = true;
			$('#wrap').animate({ marginLeft: '0' }, 500, 'easeOutBounce');
			$('#wrap .header, #wrap .footer').animate({ left: '0' }, 500, 'easeOutBounce');
		}
		else
		{
			$(this).addClass('open-nav-active');
			$navstatus = false;
			$('#wrap').animate({ marginLeft: '200px' }, 500, 'easeOutBounce');
			$('#wrap .header, #wrap .footer').animate({ left: '200px' }, 500, 'easeOutBounce');
		}
		return false;
	});
	$(window).resize(function() {
		if (!$navstatus)
		{
			$('a.open-nav').removeClass('open-nav-active');
			$('#nav-left ul.nav').css({ height: $(window).height() + 5 + 'px', overflow: 'auto' });
			if ($(document).width() > 780)
			{
				$navstatus = true;
				$('#wrap').animate({ marginLeft: '0' }, 500, 'easeOutBounce');
				$('#wrap .header, #wrap .footer').animate({ left: '0' }, 500, 'easeOutBounce');
			}
		}
	});
	/* End: Responsive Navigation */

	/* Begin: Sidebar Navigation */
	$('#nav-sidebar li').each(function(){
		if ($(this).children('ul').html())
		{
			var icon = 'down';
			if ($(this).attr('class') == 'active')
			{
				icon = 'up';
			}
			var $append = '<em class="icon-angle-' + icon + '"></em>';
			$(this).find('a:first-child').append($append);
		}
		$(this).find('li').find('em').remove();
	});

	$('#nav-sidebar li').click(function(){

		$redirect = false;

		/* Begin: Sidebar Auto Fixing */
		$('#wrap .sidebar').resize(function(){
			if ($(window).height() - 100 <= $('#wrap .sidebar ul.nav').height())
			{
				$('#wrap .sidebar').css({ position: 'relative' });
			}
			else
			{
				$('#wrap .sidebar').css({ position: 'fixed', height: '100%' });
			}
		});
		$(window).resize(function(){
			if ($(window).height() - 100 <= $('#wrap .sidebar ul.nav').height())
			{
				$('#wrap .sidebar').css({ position: 'relative' });
			}
			else
			{
				$('#wrap .sidebar').css({ position: 'fixed', height: '100%' });
			}
		});
		/* End: Sidebar Auto Fixing */

		if ($(this).find('span').is(':visible'))
		{
			var $subnav = $(this).children('ul');
			if ($subnav.html())
			{
				var $parent = $subnav.parent('li');
				var $arrow = $(this).find('em');
				if ($subnav.is(':visible'))
				{
					$subnav.slideUp(200, 'swing');
					$parent.removeClass('open');
					$arrow.addClass('icon-angle-down');
					$arrow.removeClass('icon-angle-up');
				}
				else
				{
					$subnav.slideDown(400, 'easeOutBounce');
					$parent.addClass('open');
					$arrow.addClass('icon-angle-up');
					$arrow.removeClass('icon-angle-down');
				}
			}
			else
			{
				$redirect = true;
			}
		}
		else
		{
			$redirect = true;
		}
		if ($redirect)
		{
			document.location.href = $(this).find('a').attr('href');
		}

		return false;
	});
	/* End: Sidebar Navigation */

	/* Begin: Content Scroller */
	if ($('.scroller').length > 0)
	{
		$('.scroller').mCustomScrollbar({
			autoHideScrollbar: true,
			theme: 'dark-thick'
		});
	}
	/* End: Content Scroller */

	/* Begin: Tooltips */
	$('#wrap .header a, #wrap .content .content-top *').tooltip({ placement: 'right' });
	$('#wrap .sidebar *').tooltip({ placement: 'top' });
	$('#wrap .content .content-bottom a').tooltip();
	/* End: Tooltips */
	/* Begin: Popovers */
	$('.popover-pop').popover();
	/* End: Popovers */

	/* Begin: Extended form elements  */
		/* Begin: TagsInput */
	$('input.tags').tagsInput({ width: 'auto', height: 'auto' });
	$('select.chosen-select').chosen({ allow_single_deselect: true });
		/* End: TagsInput */

		/* Begin: Input Spinner/Stepper */
	$('#stepper1').stepper();
	// Custom step
	$('#stepper2').stepper({
		wheel_step: 0.1,
		arrow_step: 0.1
	});
	// No UI
	$('#stepper3').stepper({ UI: false });
	// Limited
	$('#stepper4').stepper({ limit: [0, 10] });
	// Min limit only
	$('#stepper5').stepper({ limit: [10,] });
		/* End: Input Spinner */

		/* Begin: Dual Multi Select */
	$('#dualmultiselect1').multiSelect({});
	$('#dualmultiselect2').multiSelect({ selectableOptgroup: true });
	/* End: Dual Multi Select */
	/* Begin: Slider */
	$("#slider1").slider({ from: 1000, to: 100000, step: 500, smooth: true, round: 0, dimension: "&nbsp;$" });
	$("#slider2").slider({ from: 5, to: 50, step: 2.5, round: 1, format: { format: '##.0', locale: 'de' }, dimension: '&nbsp;€', skin: "round" });
	$("#slider3").slider({ from: 0, to: 500, heterogeneity: ['50/100', '75/250'], scale: [0, '|', 50, '|', '100', '|', 250, '|', 500], limits: false, step: 1, dimension: '&nbsp;m<small>2</small>' });
	$("#slider4").slider({ from: 1, to: 30, heterogeneity: ['50/5', '75/15'], scale: [1, '|', 3, '|', '5', '|', 15, '|', 30], limits: false, step: 1, dimension: '', skin: "blue", callback: function( value ){ console.dir( this ); } });
	$("#slider5").slider({ from: 480, to: 1020, step: 15, dimension: '', scale: ['8:00', '9:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00'], limits: false, calculate: function( value ){
        var hours = Math.floor( value / 60 );
        var mins = ( value - hours*60 );
        return (hours < 10 ? "0"+hours : hours) + ":" + ( mins == 0 ? "00" : mins );
	}});
		/* End: Slider */
		/* Begin: Datepicker */
	$('#datepicker1').datepicker({
		format: 'mm-dd-yyyy'
	});
	$('#datepicker2').datepicker();
	$('#datepicker3').datepicker();
	$('#datepicker4').datepicker();
	$('#datepicker5').datepicker();
	$('#datepicker6').datepicker();
		/* End: Datepicker */
		/* Begin: Timepicker */
	$('#timepicker1').timepicker();
	$('#timepicker2').timepicker({
		minuteStep: 1,
		template: 'modal',
		showSeconds: true,
		showMeridian: false
	});
		/* End: Timepicker */
		/* Begin: Colorpicker */
	$('.colorpicker').colorpicker();
		/* End: Colorpicker */
		/* Begin: Input Masks */
	$('.dateMask').mask('99/99/9999');
	$('.phoneMask').mask('(999) 999-9999');
	$('.tinMask').mask('99-9999999');
	$('.ssnMask').mask('999-99-9999');
	$('.prMask').mask('aaa-9999-a');
	$('.mixedMask').mask('****-****');
		/* End: Input Masks */
		/* Begin: wysihtml5 */
	$('textarea.wysihtml5').wysihtml5();
		/* End: wysihtml5 */
		/* Begin: Placeholder Fix */
		$('input, textarea').placeholder();
		/* End: Placeholder Fix */
	/* End: Extended form elements  */

	/* Begin: Data Tables */
	if ($('#dataTable1').length > 0)
	{
		$('#dataTable1').dataTable({
		    "iDisplayStart": 0,
		    "aLengthMenu": [[10, 50, 100, -1], [10, 50, 100, 'All']],
                    "bSort": false,
		    "sPaginationType": "bootstrap"
		});
	}
	/* Begin: Data Tables */

	/* Begin: File Management (elFinder) */
	if ($('#elfinder').length > 0)
	{
		var elf = $('#elfinder').elfinder({
			url : 'php/connector.php'
		}).elfinder('instance');
	}
	/* Begin: File Management (elFinder) */

	if ($('#dropzone').length > 0)
	{
		$('#dropzone').dropzone({ url: "/file/post" });
	}

    /* Begin: ScrollUp */
    $(document.body).append('<a href="#" class="scrollUp"><i class="icon-angle-up icon-2x"></i></a>');
    $(window).scroll(function(){
        if ($(this).scrollTop() > 100) {
            $('a.scrollUp').fadeIn();
        }
        else
        {
            $('a.scrollUp').fadeOut();
        }
    });
    $('a.scrollUp').click(function(){
        $("html, body").animate({ scrollTop: 0 }, 600);
        return false;
    });
    /* End: ScrollUp */

	/* Begin: Content Boxes */
	$('#wrap .middle .content .content-bottom .box .title .actions .item i.collapse-box-toggle').click(function(){
		var $icon = $(this);
		var $parentBox = $(this).parents('.box');
		var $block = $parentBox.find('.block');
		if ($block.is(':visible'))
		{
			$icon.removeClass('icon-minus');
			$icon.addClass('icon-plus');
			$parentBox.addClass('box-close');
			$block.slideUp('fast');
		}
		else
		{
			$icon.removeClass('icon-plus');
			$icon.addClass('icon-minus');
			$parentBox.removeClass('box-close');
			$block.slideDown('fast');
		}
		return false;
	});
	/* End: Content Boxes */

	/* Begin: Calendar */
	if ($('#calendar').length > 0)
	{
		var date = new Date();
		var d = date.getDate();
		var m = date.getMonth();
		var y = date.getFullYear();
		
		$('#calendar').fullCalendar({
			header: {
				left: 'prev,next today',
				center: 'title',
				right: 'month,agendaWeek,agendaDay'
			},
			editable: true,
			events: [
				{
					title: 'All Day Event',
					start: new Date(y, m, 1)
				},
				{
					title: 'Long Event',
					start: new Date(y, m, d-5),
					end: new Date(y, m, d-2)
				},
				{
					id: 999,
					title: 'Repeating Event',
					start: new Date(y, m, d-3, 16, 0),
					allDay: false
				},
				{
					id: 999,
					title: 'Repeating Event',
					start: new Date(y, m, d+4, 16, 0),
					allDay: false
				},
				{
					title: 'Meeting',
					start: new Date(y, m, d, 10, 30),
					allDay: false
				},
				{
					title: 'Lunch',
					start: new Date(y, m, d, 12, 0),
					end: new Date(y, m, d, 14, 0),
					allDay: false
				},
				{
					title: 'Birthday Party',
					start: new Date(y, m, d+1, 19, 0),
					end: new Date(y, m, d+1, 22, 30),
					allDay: false
				},
				{
					title: 'Click for Google',
					start: new Date(y, m, 28),
					end: new Date(y, m, 29),
					url: 'http://google.com/'
				}
			]
		});
	}
	/* End: Calendar */

	/* Begin: Easy Pie Chart */
	if ($('#server-usage').length > 0)
	{
		var initPieChart = function() {
			$('#server-usage .percent').easyPieChart({
				animate: 1000,
		    	barColor: function(percent) {
		        	percent /= 100;
		            return "rgb(" + Math.round(255 * percent) + ", " + Math.round(255 * (1-percent)) + ", 0)";
		        },
		        trackColor: '#d2e2e2',
		        scaleColor: false,
		        lineCap: 'butt',
		        lineWidth: 5,
		        size: 50
			});

			$('#server-usage .update').on('click', function(e) {
		    	e.preventDefault();
		        $('#server-usage .percent').each(function() {
		        	var newValue = Math.round(100*Math.random());
		            $(this).data('easyPieChart').update(newValue);
		            $('span', this).text(newValue);
		        });
			});
		};
		$(document).ready(function(){
			initPieChart();
		});
	}
	/* End: Easy Pie Chart */

	/* Begin: Form Validation */
	if ($('form.form-validation').length > 0)
	{
		$('form.form-validation').validationEngine();
	}
	if ($('#frm1').length > 0)
	{
		$('#frm1').validate();
	}
	if ($('#frm2').length > 0)
	{
		$('#frm2').validate();
	}
	/* End: Form Validation */

	/* Begin: Google PrettyPrint */
	window.prettyPrint && prettyPrint();
	/* End: Google PrettyPrint */

	/* Begin: Check All */
	$('input.checkall').change(function(){
		var $group = $('input[name="' + $(this).attr('data-group') + '"]');
		if ($(this).is(':checked'))
		{
			$group.prop('checked', true);
		}
		else
		{
			$group.prop('checked', false);
		}
	});
	/* End: Check All */

	/* Begin: Bootbox Dialogs */
	$('.bootbox-alert').on('click', function(e) {
		bootbox.alert($(this).attr('data-message'));
	});
	$('.bootbox-confirm').on('click', function(e) {
                var $d_v=$(this).attr('data-value');
		bootbox.confirm($(this).attr('data-message'), function(result, d_v){
                        if (result) {
                            $.get($d_v, {},function(json) {location.reload();});
                        }
		});
	});
	$('.bootbox-prompt').on('click', function(e) {
		bootbox.prompt($(this).attr('data-message'), function(result){
			var $alert = '';
			if (result === null)
			{
				$alert = 'Prompt dismissed';
			}
			else
			{
				$alert = result;
			}
			alert($alert);
		});
	});
	$('.bootbox-dialog').on('click', function(e) {
		bootbox.dialog("I am a custom dialog", [
			{
				"label" : "Success!",
				"class" : "btn-success",
				"callback": function() {
					alert('great success');
				}
			}, {
				"label" : "Danger!",
				"class" : "btn-danger",
				"callback": function() {
					alert('uh oh, look out!');
				}
			}, {
				"label" : "Click ME!",
				"class" : "btn-primary",
				"callback": function() {
					alert('Primary button');
				}
			}, {
				"label" : "Just a button...",
				"callback": function() {
					alert('Just a button...');
				}
			}
		]);
	});
	/* End: Bootbox Dialogs */

	/* Begin: Theme Roller */
	var themeRoller = function(theme){
		var $oldThemeSplit = $('#css-theme').attr('href').split('/');
		var $themePath = '';
		for ($i = 0; $i < $oldThemeSplit.length - 1; $i++)
		{
			$themePath += $oldThemeSplit[$i] + '/';
		}
		$themePath += 'theme.' + theme + '.css';
		$('#css-theme').attr('href', $themePath);
		$.cookie('theme', theme);
	}
	if ($.cookie('theme'))
	{
		//alert($.cookie('theme'));
		themeRoller($.cookie('theme'));
	}
	$('#theme-roller li a').click(function(){
		var $newTheme = $(this).attr('href').replace('#', '');
		themeRoller($newTheme);
		return false;
	});
	/* End: Theme Roller */

	/* Begin: Page Preloader */
	$window.load(function() {
		$('#preloader .inline').fadeOut();
		$('#preloader').delay(350).fadeOut('slow');
	});
	/* End: Page Preloader */

}(window.jQuery);
