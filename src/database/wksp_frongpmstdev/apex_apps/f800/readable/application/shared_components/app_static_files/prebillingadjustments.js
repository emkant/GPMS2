const pageId = Number(document.getElementById("pFlowStepId").value);

function currencyFormatter(p_amount,p_currency) {
    var currency_symbols_arr = {
        'USD': '$', // US Dollar
        'EUR': '€', // Euro
        'CRC': '₡', // Costa Rican Colón
        'GBP': '£', // British Pound Sterling
        'ILS': '₪', // Israeli New Sheqel
        'INR': '₹', // Indian Rupee
        'JPY': '¥', // Japanese Yen
        'KRW': '₩', // South Korean Won
        'NGN': '₦', // Nigerian Naira
        'PHP': '₱', // Philippine Peso
        'PLN': 'zł', // Polish Zloty
        'PYG': '₲', // Paraguayan Guarani
        'THB': '฿', // Thai Baht
        'UAH': '₴', // Ukrainian Hryvnia
        'VND': '₫', // Vietnamese Dong
    };
    var i_currency = currency_symbols_arr[p_currency];

    return i_currency+ (p_amount).toFixed(2).replace(/\d(?=(\d{3})+\.)/g, '$&,');

}

function saveTokenToSession(token, user, preferredName,timeStamp,tokenDuration) {
	let spinner = apex.util.showSpinner();
    // alert(token);
    //  alert(timeStamp);
	apex.server.process('SET_ACCESS_TOKEN', {
		x01: token,
		x02: user,
		x03: preferredName,
        x04: timeStamp,
        x05: tokenDuration
	})
		.then(response => {
			// Reload the page, with the access token now available in the session
			if (response.ok) {
                // apex.item('G_TOKEN_AVAILABLE').setValue('Y');
				window.location.reload();
                // window.location = 'https://g15d023dedae272-fronteragpmsdev.adb.us-ashburn-1.oraclecloudapps.com/ords/r/frongpmstdev/prebillingadjustments/pba?p2_agreement_number=ACA-1';
				// void (0);
			}
			// An error occurred
			else {
				spinner.remove();
				apex.message.clearErrors();
				apex.message.showErrors({
					type: "error",
					location: "page",
					message: `Unable to save access token. ${response.sqlerrm || 'Unknown error.'}`,
					unsafe: true
				});
			}
		})
}

async function getAccessToken(baseUrl) {
	// Path to the servlet, Ajax fetch options, and a delay to allow the popup to load
	let url = baseUrl + "/fscmUI/HedTokenGenerationServlet?response_type=code";
	let opts
    = {
		'credentials': 'include'
	};
	let loadTime = 3000;
	//let spinner = apex.util.showSpinner();
    // alert(url);
	await fetch(url, opts)
		.then(response => response.json())
		.then(data => {
			//spinner.remove();
			saveTokenToSession(data.token, data.user, data.preferredName,data.timeStamp,data.tokenDuration);
		})
		.catch(error => {
			//spinner.remove();
			apex.message.clearErrors();
			// apex.message.showErrors({
			// 	type: "error",
			// 	location: "page",
			// 	message: "Unable to obtain access token; " + error,
			// 	unsafe: true
			// });
          /*  Swal.fire({
                  icon: 'error',
                  title: 'Access Denied',
                  text: 'You do not have necessary privileges to access this application!',
                  allowOutsideClick: false,
                  allowEscapeKey: false,
                  allowEnterKey : false,
                  confirmButtonText: 'Try Again'
                 }) .then((result) =>{
                     if (result.isConfirmed){
                         window.location.reload();
                     }
                 })
                 ;*/
		});
}

// Function to set the regions height correctly on Page 2
if (pageId === 2) {
	function set_height() {
		var left1 = $("#ProjectDetails").height();
		var left2 = $("#chart_parent").height();
		var rit1 = $("#TrustBalance").height();
		var rit2 = $("#CostSummary").height();
		var rit3 = $("#billing").height();
		var total_left = left1 + left2;
		var total_rit = rit1 + rit2 + rit3;
		var diff = total_left - total_rit;
		if (diff < 0) {
			var abs_diff = Math.abs(diff);
			$("#ProjectDetails").height(left1 + (abs_diff / 2));
			//$("#chart_parent").css('margin-top',abs_diff/2);
			$("#chart_parent").height(left2 + (abs_diff / 2));
		}
		else if (diff > 0) {
			$("#TrustBalance").height(rit1 + (diff / 3));

			$("#CostSummary").height(rit2 + (diff / 3));
			//$("#CostSummary").css('margin-top',diff/6);
			$("#billing").height(rit3 + (diff / 3));
			//$("#billing").css('margin-top',diff/6);
			//$("#TrustBalance").css('padding-top',diff/3);
		}
	}
	function init_page2() {
		$(".t-Report-report tr:last td").css("font-weight", "700");
		$("#P2_CHANGE_GRAPHS").parent().prepend($("#FEE_ADJ"));
		$("#chart_parent .t-Region-headerItems--buttons").append($("#P2_CHANGE_GRAPHS_CONTAINER").parent().contents());

	}
}
// Function to Hide and Show Buttons for Adjustment on Page 6

if (pageId === 6) {
	function hideShowButtons() {
		var flag = apex.item("P6_COLL_CHANGED").getValue();
		if (flag == 'Y') {
			apex.item("CREATE_ADJ").show();
			apex.item("CALC").hide();
		}
		else {
			apex.item("CALC").show();
			apex.item("CREATE_ADJ").hide();
		}
	}

	function init_page6() {
		hideShowButtons();
	}
}

var adder = 0;
function setTimer() {
  apexProgressBar('P0_PROGRESS_BAR2').show();
  apex.item('P0_PROGRESS_BAR2').setValue(0);
  apex.item('P0_PROGRESS_SEQ').setValue(0);
  var refreshIntervalId = setInterval(setProgressValue, 2000);
  apex.item('P0_INTERVAL_ID').setValue(refreshIntervalId);
  async function setProgressValue() {
      adder = adder +1;
      apex.item('P0_PROGRESS_SEQ').setValue(adder);
      await apex.server.process('Percentage_for_the_progress', {
          pageItems: '#P0_PROGRESS_BAR2,#P0_PROGRESS_SEQ'
      },
          {
              dataType: 'text', success: function (pData) {
                  //   alert(pData);
                  const obj = JSON.parse(pData);
                  //   alert(obj);
                  //   alert(obj.percent);
                  // apex.item('P0_PROGRESS_BAR2').setValue(pData[percent]);
                  apexProgressBar('P0_PROGRESS_BAR2').setValues({
                      percentage: obj.percent,
                      message: obj.message, duration: 200
                  });
              },error: function(pData){
                  console.log(pData);
              }
          })
  }
}

function endTimer() {
  apexProgressBar('P0_PROGRESS_BAR2').setValues({ percentage: 100, message: "Completed..", immediate: true });
  apexProgressBar('P0_PROGRESS_BAR2').hide();
  apex.item('P0_PROGRESS_BAR2').setValue(0);
  clearInterval(apex.item('P0_INTERVAL_ID').getValue());
}



-- sqlcl_snapshot {"hash":"07f8759ad2a2ca3c949e76081ad41de5b78f5dfc","type":"APEX_APPLICATION","name":"f800","schemaName":"WKSP_FRONGPMSTDEV"}