/* =====================
Setup
===================== */

var map = L.map('map', {
  center: [39.953627, -75.198742],
  zoom: 14,
  zoomControl: true
});

var Hydda_Base = L.tileLayer('https://{s}.tile.openstreetmap.se/hydda/base/{z}/{x}/{y}.png', {
   attribution: 'Tiles courtesy of <a href="http://openstreetmap.se/" target="_blank">OpenStreetMap Sweden</a> &mdash; Map data &copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
   minZoom: 0,
   maxZoom: 20,
   ext: 'png'
 }).addTo(map);

var legend = L.control({position: 'bottomright'});

legend.onAdd = function (map) {
  var div = L.DomUtil.create('div', 'info legend'),
  grades = ["Restaurant", "Bar", "Grocer", "Beer, Wine, Spirits shop"],
  labels = [];

  // loop through our density intervals and generate a label with a colored square for each interval
  for (var i = 0; i < grades.length; i++) {
    div.innerHTML +=
    '<i style="background:' + getColor(grades[i]) + '"></i> ' +
    grades[i] + '<br>';
  }

  return div;
};

legend.addTo(map);

$('#previous').hide();
$('#explore').hide();

/* =====================
Helper functions
===================== */

var defaultView = function(){
  map.setView([39.953627, -75.198742], 14);
};

/* =====================
Styling
===================== */

var popup = function(feature) {
  thepopup = L.popup({className: 'popup'})
      .setContent(
        feature.properties.location_name +
        "<br>" +
        "<br> Daily visits </em>" +
        "<br><em class='popup-body'> Before order </em>" +
        feature.properties.before +
        "<br><em class='popup-body'> After order </em>" +
        feature.properties.after
      );
    return(thepopup);
};

function getColor(c) {
    return c == "Restaurant" ? '#407EC9' :
           c == "Bar" ? '#DC4405' :
           c == "Grocer" ? '#4C8D2B' :
           c == "Beer, Wine, Spirits shop" ? '#76232F' :
                      '#D7D2CB';
                    }

function getRadius(feature) {
  if (feature.properties.before - feature.properties.after <= 0) { return 0 }
  else { return (feature.properties.before - feature.properties.after) / feature.properties.before };
}

function pointStyle(feature) {
    return {
        fillColor: getColor(feature.properties.category),
        weight: 0.5,
        opacity: 1,
        color: 'white',
        dashArray: '3',
        fillOpacity: 0.7,
        radius: (getRadius(feature) * 10)
    };
}

var myFilter = function(feature) {
  return feature.properties.category == variable;
};

/* =====================
Data
===================== */

var visits = "https://raw.githubusercontent.com/asrenninger/coronadelphia/master/data/beforeandafter.geojson";

/* =====================
Functionality
===================== */
var parsedData;
var polyparsed;

$.ajax(visits).done(function(visits) {
  // Parse JSON
  parsedVisits = JSON.parse(visits);
  featureGroup = L.geoJson(parsedVisits, {
    pointToLayer: function(feature, latlng) {
        return new L.CircleMarker(latlng);
    },
    style: pointStyle,
    onEachFeature: function(feature, layer) {
        layer.bindPopup(popup(feature));
    }
  });

  featureGroup.addTo(map);

});

var currentSlide = -1;

var loadSlide = function(slide) {

  map.removeLayer(featureGroup);

  $('.title').text(slide.title);
  $('.text').text(slide.description);

  variable = slide.data;

  featureGroup = L.geoJson(parsedVisits, {
    pointToLayer: function(feature, latlng) {
        return new L.CircleMarker(latlng);
    },
    style: pointStyle,
    filter: myFilter,
    onEachFeature: function(feature, layer) {
        layer.bindPopup(popup(feature));
    }
  });

  featureGroup.addTo(map);

  map.setView(slide.xy, slide.z);

};

var next = function() {
  if (currentSlide == slides.length - 1) {
  } else {
    $('#next').show()
    $('#previous').show()
    currentSlide = currentSlide + 1
    loadSlide(slides[currentSlide])
  }

  if (currentSlide == slides.length - 1) {
    $('#next').hide();
    $('#explore').show();
  }
};

var previous = function() {
  if (currentSlide == 0) {
    location.reload()
  } else {
    $('#next').show()
    currentSlide = currentSlide - 1
    loadSlide(slides[currentSlide])
  }

  if (currentSlide == -1) {
    $('#previous').hide()
  }

};

var explore = function() {
    map.removeLayer(featureGroup);
    map.setView([39.953627, -75.198742], 13);

    featureGroup = L.geoJson(parsedVisits, {
      pointToLayer: function(feature, latlng) {
          return new L.CircleMarker(latlng);
      },
      style: pointStyle,
      onEachFeature: function(feature, layer) {
          layer.bindPopup(popup(feature));
      }
    });

    featureGroup.addTo(map);

    $('#next').hide();
    $('#previous').hide();
    $('#explore').text("Reset");

    $('.title').text("Explore for yourself!");
    $('.text').text("Zoom in on your neighborhood and click on a point to see the numbers behind the last month of service there.");

};

$('#next').click(function(e) {
  next();
});

$('#previous').click(function(e) {
  previous();
});

$('#explore').click(function(e) {
  explore();
});
