$(document).on("change",".recipient_country", function(){
	var country_id = $(this).val() 
	var country_field_name = $(this).attr("name");
	var state_field =$('[name="'+country_field_name.replace('country_id','state_id')+'"]') ;
	state_field.empty();

	$.get("/api/v1/states?country_id="+country_id).success(function(data){
		console.log(data["states"]);
		if (data["states"] != " "){
			$.each(data["states"], function(i , val){
			state_field.append($('<option>', { 
			       value: val.id,
			       text : val.name 
			   }));

			});
		}	
	});
});

$(document).ready(function(){
	$(".recipient_country").prepend('<option value ="" disabled = "disabled" selected= "selected">Select Country</option>');
});