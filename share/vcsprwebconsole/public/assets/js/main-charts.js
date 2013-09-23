!function ($) {

	var chartColours = ['#507878', '#696c24', '#1f84cb', '#2da1a1', '#505c5c', '#52954e', '#ac4fb2'];

	/* Begin: Dynamic Update Chart */
	if ($('#dynamicUptadeChart').length > 0)
	{
		$(function () {
			// we use an inline data source in the example, usually data would
		    // be fetched from a server
		    var data = [], totalPoints = 300;
		    function getRandomData() {
		        if (data.length > 0)
		            data = data.slice(1);

		        // do a random walk
		        while (data.length < totalPoints) {
		            var prev = data.length > 0 ? data[data.length - 1] : 50;
		            var y = prev + Math.random() * 10 - 5;
		            if (y < 0)
		                y = 0;
		            if (y > 100)
		                y = 100;
		            data.push(y);
		        }

		        // zip the generated y values with the x values
		        var res = [];
		        for (var i = 0; i < data.length; ++i)
		            res.push([i, data[i]])
		        return res;
		    }

		    // Update interval
		    var updateInterval = 200;

		    // setup plot
		    var options = {
		        series: { 
		        	grow: {active:false}, //disable auto grow
		        	shadowSize: 0, // drawing is faster without shadows
		        	lines: {
	            		show: true,
	            		fill: true,
	            		lineWidth: 2,
	            		steps: false
		            }
		        },
		        grid: {
					show: true,
				    aboveData: false,
				    color: "#3f3f3f" ,
				    labelMargin: 5,
				    axisMargin: 0, 
				    borderWidth: 0,
				    borderColor:null,
				    minBorderMargin: 5 ,
				    clickable: true, 
				    hoverable: true,
				    autoHighlight: false,
				    mouseActiveRadius: 20
				}, 
				colors: chartColours,
		        tooltip: true, //activate tooltip
				tooltipOpts: {
					content: "Value is : %y.0",
					shifts: {
						x: -30,
						y: -50
					}
				},	
		        yaxis: { min: 0, max: 100 },
		        xaxis: { show: true}
		    };
		    var plot = $.plot($('#dynamicUptadeChart'), [ getRandomData() ], options);

		    function update() {
		        plot.setData([ getRandomData() ]);
		        // since the axes don't change, we don't need to call plot.setupGrid()
		        plot.draw();
		        
		        setTimeout(update, updateInterval);
		    }
		    update();
	    });
	}
	/* End: Dynamic Update Chart */

	/* Begin: Simple Chart */
	if ($('#simpleChart').length > 0)
	{
		$(function () {
			var sin = [], cos = [];
		    for (var i = 0; i < 14; i += 0.5) {
		        sin.push([i, Math.sin(i)]);
		        cos.push([i, Math.cos(i)]);
		    }
		    //graph options
			var options = {
					grid: {
						show: true,
					    aboveData: true,
					    color: "#3f3f3f" ,
					    labelMargin: 5,
					    axisMargin: 0, 
					    borderWidth: 0,
					    borderColor:null,
					    minBorderMargin: 5 ,
					    clickable: true, 
					    hoverable: true,
					    autoHighlight: true,
					    mouseActiveRadius: 20
					},
			        series: {
			        	grow: {active: false},
			            lines: {
		            		show: true,
		            		fill: false,
		            		lineWidth: 4,
		            		steps: false
			            	},
			            points: {
			            	show:true,
			            	radius: 5,
			            	symbol: "circle",
			            	fill: true,
			            	borderColor: "#fff"
			            }
			        },
			        legend: { position: "se" },
			        colors: chartColours,
			        shadowSize:1,
			        tooltip: true, //activate tooltip
					tooltipOpts: {
						content: "%s : %y.3",
						shifts: {
							x: -30,
							y: -50
						}
					}
			};
			var plot = $.plot($('#simpleChart'),
	           [{
	    			label: "Sin", 
	    			data: sin,
	    			lines: {fillColor: "#f2f7f9"},
	    			points: {fillColor: "#00c8f3"}
	    		}, 
	    		{	
	    			label: "Cos", 
	    			data: cos,
	    			lines: {fillColor: "#fff8f2"},
	    			points: {fillColor: "#4ece00"}
	    	}], options);
	    });
	}
	/* End: Simple Chart */

	/* End: Pie Chart */
	if ($('#pieChart').length > 0)
	{
		$(function () {
			var data = [
			    { label: "Firefox",  data: 30, color: "#00a1cb"},
			    { label: "Chrome",  data: 25, color: "#ed7a53"},
			    { label: "IE",  data: 21, color: "#9FC569"},
			    { label: "Opera",  data: 12, color: "#bbdce3"},
			    { label: "Safari",  data: 7, color: "#9a3b1b"},
			    { label: "Others",  data: 5, color: "#5a8022"}
			];

		    $.plot($('#pieChart'), data, 
			{
				series: {
					pie: { 
						show: true,
						highlight: {
							opacity: 0.1
						},
						radius: 1,
						stroke: {
							color: '#fff',
							width: 2
						},
						startAngle: 2,
					    combine: {
		                    color: '#353535',
		                    threshold: 0.05
		                },
		                label: {
		                    show: true,
		                    radius: 1,
		                    formatter: function(label, series){
		                        return '<div class="pie-chart-label">'+label+'&nbsp;'+Math.round(series.percent)+'%</div>';
		                    }
		                }
					},
					grow: {	active: false}
				},
				legend:{show:false},
				grid: {
		            hoverable: true,
		            clickable: true
		        },
		        tooltip: true, //activate tooltip
				tooltipOpts: {
					content: "%s : %y.1"+"%",
					shifts: {
						x: -30,
						y: -50
					}
				}
			});
		});
	}
	/* End: Pie Chart */

	/* Begin: Donut Chart */
	if ($('#donutChart').length > 0)
	{
		$(function () {
			var data = [
			    { label: "USA",  data: 38, color: "#88bbc8"},
			    { label: "Brazil",  data: 23, color: "#ed7a53"},
			    { label: "India",  data: 15, color: "#9FC569"},
			    { label: "Turkey",  data: 9, color: "#bbdce3"},
			    { label: "France",  data: 7, color: "#9a3b1b"},
			    { label: "China",  data: 5, color: "#5a8022"},
			    { label: "Germany",  data: 3, color: "#2c7282"}
			];

		    $.plot($('#donutChart'), data, 
			{
				series: {
					pie: { 
						show: true,
						innerRadius: 0.4,
						highlight: {
							opacity: 0.1
						},
						radius: 1,
						stroke: {
							color: '#fff',
							width: 8
						},
						startAngle: 2,
					    combine: {
		                    color: '#353535',
		                    threshold: 0.05
		                },
		                label: {
		                    show: true,
		                    radius: 1,
		                    formatter: function(label, series){
		                        return '<div class="pie-chart-label">'+label+'&nbsp;'+Math.round(series.percent)+'%</div>';
		                    }
		                }
					},
					grow: {	active: false}
				},
				legend:{show:false},
				grid: {
		            hoverable: true,
		            clickable: true
		        },
		        tooltip: true, //activate tooltip
				tooltipOpts: {
					content: "%s : %y.1"+"%",
					shifts: {
						x: -30,
						y: -50
					}
				}
			});
		});
	}
	/* End: Donut Chart */

	/* Begin: Bar Chart */
	if ($('#barChart').length > 0)
	{
		$(function () {
	    var d1_1 = [
	        [1325376000000, 120],
	        [1328054400000, 70],
	        [1330560000000, 100],
	        [1333238400000, 60],
	        [1335830400000, 35]
	    ];
	 
	    var d1_2 = [
	        [1325376000000, 80],
	        [1328054400000, 60],
	        [1330560000000, 30],
	        [1333238400000, 35],
	        [1335830400000, 30]
	    ];
	 
	    var d1_3 = [
	        [1325376000000, 80],
	        [1328054400000, 40],
	        [1330560000000, 30],
	        [1333238400000, 20],
	        [1335830400000, 10]
	    ];
	 
	    var d1_4 = [
	        [1325376000000, 15],
	        [1328054400000, 10],
	        [1330560000000, 15],
	        [1333238400000, 20],
	        [1335830400000, 15]
	    ];
	 
	    var data1 = [
	        {
	            label: "Product 1",
	            data: d1_1,
	            bars: {
	                show: true,
	                barWidth: 12*24*60*60*300,
	                fill: true,
	                lineWidth: 1,
	                order: 1,
	                fillColor:  "#AA4643"
	            },
	            color: "#AA4643"
	        },
	        {
	            label: "Product 2",
	            data: d1_2,
	            bars: {
	                show: true,
	                barWidth: 12*24*60*60*300,
	                fill: true,
	                lineWidth: 1,
	                order: 2,
	                fillColor:  "#89A54E"
	            },
	            color: "#89A54E"
	        },
	        {
	            label: "Product 3",
	            data: d1_3,
	            bars: {
	                show: true,
	                barWidth: 12*24*60*60*300,
	                fill: true,
	                lineWidth: 1,
	                order: 3,
	                fillColor:  "#4572A7"
	            },
	            color: "#4572A7"
	        },
	        {
	            label: "Product 4",
	            data: d1_4,
	            bars: {
	                    show: true,
	                barWidth: 12*24*60*60*300,
	                fill: true,
	                lineWidth: 1,
	                order: 4,
	                fillColor:  "#80699B"
	            },
	            color: "#80699B"
	        }
	    ];
	 
		    $.plot($("#barChart"), data1, {
		        xaxis: {
		            min: (new Date(2011, 11, 15)).getTime(),
		            max: (new Date(2012, 04, 18)).getTime(),
		            mode: "time",
		            timeformat: "%b",
		            tickSize: [1, "month"],
		            monthNames: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
		            tickLength: 0, // hide gridlines
		            axisLabel: 'Month',
		            axisLabelUseCanvas: true,
		            axisLabelFontSizePixels: 12,
		            axisLabelFontFamily: 'Verdana, Arial, Helvetica, Tahoma, sans-serif',
		            axisLabelPadding: 5
		        },
		        yaxis: {
		            axisLabel: 'Value',
		            axisLabelUseCanvas: true,
		            axisLabelFontSizePixels: 12,
		            axisLabelFontFamily: 'Verdana, Arial, Helvetica, Tahoma, sans-serif',
		            axisLabelPadding: 5
		        },
		        grid: {
		            hoverable: true,
		            clickable: false,
		            borderWidth: 1
		        },
		        series: {
		            shadowSize: 1
		        },
		        tooltip: true
		    });
		 
		    function getMonthName(newTimestamp) {
		        var d = new Date(newTimestamp);
		 
		        var numericMonth = d.getMonth();
		        var monthArray = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
		 
		        var alphaMonth = monthArray[numericMonth];
		 
		        return alphaMonth;
		    }

		    $("#barChart").bind("plothover", function (event, pos, item) {
		        if (item) {
		            if (previousPoint != item.datapoint) {
		                previousPoint = item.datapoint;
		                $("#flot-tooltip").remove();
		 
		                var originalPoint;
		 
		                if (item.datapoint[0] == item.series.data[0][3]) {
		                    originalPoint = item.series.data[0][0];
		                } else if (item.datapoint[0] == item.series.data[1][3]){
		                    originalPoint = item.series.data[1][0];
		                } else if (item.datapoint[0] == item.series.data[2][3]){
		                    originalPoint = item.series.data[2][0];
		                } else if (item.datapoint[0] == item.series.data[3][3]){
		                    originalPoint = item.series.data[3][0];
		                } else if (item.datapoint[0] == item.series.data[4][3]){
		                    originalPoint = item.series.data[4][0];
		                }
		 
		                var x = getMonthName(originalPoint);
		                y = item.datapoint[1];
		                z = item.series.color;
		 
		                showTooltip(item.pageX, item.pageY,
		                    "<b>" + item.series.label + "</b><br /> " + x + " = " + y + "&deg;C",
		                    z);
		            }
		        } else {
		            $("#flot-tooltip").remove();
		            previousPoint = null;
		        }
		    });

	    });
	}
    /* Begin: Bar Chart */

	/* Begin: Sparkline */
	$(function () {
		if ($('#salesSparkline span').length > 0)
		{
			$("#salesSparkline span").sparkline([65, 33, 28, 77, 56, 84, 28, 77, 56, 84], {
		    	type: 'bar',
		    	barWidth: 6,
		    	barColor: '#6f8e8c'
			});
		}
		if ($('#visitsSparkline span').length > 0)
		{
			$("#visitsSparkline span").sparkline([5,6,7,9,9,5,3,2,2,4,6,7], {
			    type: 'line',
			    lineColor: '#6b6b7c',
			    spotColor: '#4abf48',
			    minSpotColor: '#ff0087',
			    fillColor: '#d2e2e2'
			});
		}
		if ($('#otherSparkline span').length > 0)
		{
			$("#otherSparkline span").sparkline([1,1,0,1,0,-1,1,-1,0,0,1,1 ], {
			    type: 'tristate',
			    posBarColor: '#6f8e8c',
			    negBarColor: '#d2e2e2',
			    barWidth: 6
			});
		}
	});
	/* End: Sparkline */

}(window.jQuery);