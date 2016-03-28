var rendererOptions = {
    draggable: true
};
var directionsService = new google.maps.DirectionsService();
var directionsDisplay = new google.maps.DirectionsRenderer(rendererOptions);
var map;
var australia = new google.maps.LatLng(37.4419, -122.1419);
function direction_map(pick_location, dest_location) {
    var mapOptions = {
        zoom: 7,
        mapTypeId: google.maps.MapTypeId.ROADMAP,
        center: australia,
        draggable: true
    };
    map = new google.maps.Map(document.getElementById('map-canvas'), mapOptions);
    directionsDisplay.setMap(map);
    calcRoute(map, pick_location, dest_location);
}
function calcRoute(map, pick_location, dest_location) {
    var request = {
        origin: pick_location,
        destination: dest_location,
        travelMode: google.maps.DirectionsTravelMode.DRIVING
    };
    directionsService.route(request, function (response, status) {
        if (status == google.maps.DirectionsStatus.OK) {
            directionsDisplay.setDirections(response);
        } else {
            hudMsg("error", "There is problem with locations you have entered: ");
            return false;
        }
    });
}