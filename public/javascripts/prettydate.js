pretty = function(date) {
	var diff = (((new Date()).getTime() - date.getTime()) / 1000),
			day_diff = Math.floor(diff / 86400);
	
	if(diff < 0)
		day_diff = Math.floor(-1*diff / 86400);
	
	if ( isNaN(day_diff) || day_diff < 0 || day_diff >= 31 ) {
		return date.getMonth()+'/'+date.getDay()+'/'+date.getFullYear();
	}
			

	return day_diff == 0 && (
				diff < 0 && diff > -60 && "in moments" ||
				diff > 0 && diff < 60 && "just now" ||
				
				diff < 0 && diff > -120 && "in 1 minute" ||
				diff > 0 && diff < 120 && "1 minute ago" ||
				
				diff < 0 && diff > -3600 && "in " + Math.floor( diff*-1 / 60 ) + " minutes" ||
				diff > 0 && diff < 3600 && Math.floor( diff / 60 ) + " minutes ago" ||
				
				diff < 0 && diff > -7200 && "in 1 hour" ||
				diff > 0 && diff < 7200 && "1 hour ago" ||
				
				diff < 0 && diff > -86400 && "in " + Math.floor( diff*-1 / 3600 ) + " hours " ||
				diff > 0 && diff < 86400 && Math.floor( diff / 3600 ) + " hours ago") ||
				
			diff > 0 && day_diff == 1 && "Yesterday" ||
			diff < 0 && day_diff == 1 && "Tomorrow" ||
			
			diff > 0 && day_diff < 7 && day_diff + " days ago" ||
			diff < 0 && day_diff < 7 && "in " + day_diff + " days" ||
			
			diff > 0 && day_diff < 31 && Math.ceil( day_diff / 7 ) + " weeks ago" ||
			diff < 0 && day_diff < 31 && "in " + Math.ceil( day_diff / 7 ) + " weeks";
}