var simplemaps_countrymap_mapdata = {
  main_settings: {
    //General settings
    width: "responsive", //'700' or 'responsive'
    background_color: "#FFFFFF",
    background_transparent: "yes",
    border_color: "#ffffff",

    //State defaults
    state_description: "State description",
    state_color: "#88A4BC",
    state_hover_color: "#3B729F",
    state_url: "",
    border_size: 1.5,
    all_states_inactive: "no",
    all_states_zoomable: "yes",

    //Location defaults
    location_description: "Location description",
    location_url: "",
    location_color: "#FF0067",
    location_opacity: 0.8,
    location_hover_opacity: 1,
    location_size: 25,
    location_type: "square",
    location_image_source: "frog.png",
    location_border_color: "#FFFFFF",
    location_border: 2,
    location_hover_border: 2.5,
    all_locations_inactive: "no",
    all_locations_hidden: "no",

    //Label defaults
    label_color: "#ffffff",
    label_hover_color: "#ffffff",
    label_size: 16,
    label_font: "Arial",
    label_display: "auto",
    label_scale: "yes",
    hide_labels: "no",
    hide_eastern_labels: "no",

    //Zoom settings
    zoom: "yes",
    manual_zoom: "yes",
    back_image: "no",
    initial_back: "no",
    initial_zoom: "-1",
    initial_zoom_solo: "no",
    region_opacity: 1,
    region_hover_opacity: 0.6,
    zoom_out_incrementally: "yes",
    zoom_percentage: 0.99,
    zoom_time: 0.5,

    //Popup settings
    popup_color: "white",
    popup_opacity: 0.9,
    popup_shadow: 1,
    popup_corners: 5,
    popup_font: "12px/1.5 Verdana, Arial, Helvetica, sans-serif",
    popup_nocss: "no",

    //Advanced settings
    div: "map",
    auto_load: "yes",
    url_new_tab: "no",
    images_directory: "default",
    fade_time: 0.1,
    link_text: "View Website",
    popups: "detect"
  },
  state_specific: {
    IQAN: {
      name: "Al-Anbar",
      description: "default",
      color: "default",
      hover_color: "default",
      url: "default"
    },
    IQAR: {
      name: "Arbil",
      description: "default",
      color: "default",
      hover_color: "default",
      url: "default"
    },
    IQBA: {
      name: "Al-Basrah",
      description: "default",
      color: "default",
      hover_color: "default",
      url: "default"
    },
    IQBB: {
      name: "Babil",
      description: "default",
      color: "default",
      hover_color: "default",
      url: "default"
    },
    IQBG: {
      name: "Baghdad",
      description: "default",
      color: "default",
      hover_color: "default",
      url: "default"
    },
    IQDA: {
      name: "Dihok",
      description: "default",
      color: "default",
      hover_color: "default",
      url: "default"
    },
    IQDI: {
      name: "Diyala",
      description: "default",
      color: "default",
      hover_color: "default",
      url: "default"
    },
    IQDQ: {
      name: "Dhi-Qar",
      description: "default",
      color: "default",
      hover_color: "default",
      url: "default"
    },
    IQKA: {
      name: "Karbala'",
      description: "default",
      color: "default",
      hover_color: "default",
      url: "default"
    },
    IQKI: {
      name: "Kirkūk",
      description: "default",
      color: "default",
      hover_color: "default",
      url: "default"
    },
    IQMA: {
      name: "Maysan",
      description: "default",
      color: "default",
      hover_color: "default",
      url: "default"
    },
    IQMU: {
      name: "Al-Muthannia",
      description: "default",
      color: "default",
      hover_color: "default",
      url: "default"
    },
    IQNA: {
      name: "An-Najaf",
      description: "default",
      color: "default",
      hover_color: "default",
      url: "default"
    },
    IQNI: {
      name: "Ninawa",
      description: "default",
      color: "default",
      hover_color: "default",
      url: "default"
    },
    IQQA: {
      name: "Al-Qādisiyyah",
      description: "default",
      color: "default",
      hover_color: "default",
      url: "default"
    },
    IQSD: {
      name: "Sala ad-Din",
      description: "default",
      color: "default",
      hover_color: "default",
      url: "default"
    },
    IQSU: {
      name: "As-Sulaymaniyah",
      description: "default",
      color: "default",
      hover_color: "default",
      url: "default"
    },
    IQWA: {
      name: "Wasit",
      description: "default",
      color: "default",
      hover_color: "default",
      url: "default"
    }
  },
  locations: {
    "0": {
      name: "Baghdad",
      lat: "33.340582",
      lng: "44.400876"
    }
  },
  labels: {
    IQAN: {
      name: "Al-Anbar",
      parent_id: "IQAN"
    },
    IQAR: {
      name: "Arbil",
      parent_id: "IQAR"
    },
    IQBA: {
      name: "Al-Basrah",
      parent_id: "IQBA"
    },
    IQBB: {
      name: "Babil",
      parent_id: "IQBB"
    },
    IQBG: {
      name: "Baghdad",
      parent_id: "IQBG"
    },
    IQDA: {
      name: "Dihok",
      parent_id: "IQDA"
    },
    IQDI: {
      name: "Diyala",
      parent_id: "IQDI"
    },
    IQDQ: {
      name: "Dhi-Qar",
      parent_id: "IQDQ"
    },
    IQKA: {
      name: "Karbala'",
      parent_id: "IQKA"
    },
    IQKI: {
      name: "Kirkūk",
      parent_id: "IQKI"
    },
    IQMA: {
      name: "Maysan",
      parent_id: "IQMA"
    },
    IQMU: {
      name: "Al-Muthannia",
      parent_id: "IQMU"
    },
    IQNA: {
      name: "An-Najaf",
      parent_id: "IQNA"
    },
    IQNI: {
      name: "Ninawa",
      parent_id: "IQNI"
    },
    IQQA: {
      name: "Al-Qādisiyyah",
      parent_id: "IQQA"
    },
    IQSD: {
      name: "Sala ad-Din",
      parent_id: "IQSD"
    },
    IQSU: {
      name: "As-Sulaymaniyah",
      parent_id: "IQSU"
    },
    IQWA: {
      name: "Wasit",
      parent_id: "IQWA"
    }
  },
  legend: {
    entries: []
  },
  regions: {}
};