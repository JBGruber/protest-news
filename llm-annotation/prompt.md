Analyze the following German news article and extract structured protest data as JSON.  
Each protest = one object in an array. Return only JSON, no explanations.  

Article Title: {article_title}
Publication Date: {article_date}
Article Text: {article_text}

Schema:
{{
  "is_protest": "yes/no/unsure",
  "event_date": "YYYY-MM-DD or null",
  "number_of_days": "number for multi-day events or 1 for a single-day event",
  "location": {{
    "square_institution": "...",
    "city": "...",
    "bundesland": "...",
    "country": "..."
  }},
  "protest_size_estimates": [
    {{
      "source_type": "...",
      "text": "how the number is described in the text, e.g., 'hundreds' or 'dozens'",
      "numerical_value": "number derived from text using the most conservative estimate (so for 'dozens': 24, for 'hundreds': 200, etc.) or 'unknown'",
      "source_name": "..."
    }},
    {{...}}
  ]
  "main_issue": "...",
  "topics": [
    {{
      "topic_name": "...",
      "confidence": "high/medium/low",
      "relevance": "primary/secondary",
      "citations": ["verbatim text extract 1", "verbatim text extract 2"]
    }}
  ],
  "protest_slogan": "... or null",
  "target": "...",
  "organizations": ["..."],
  "participant_demographics": [
    {{
      "group": "...",
      "citations": ["..."]
    }}
  ],
  "counterprotestors": {{
    "reported": true/false,
    "who": "...",
    "number": "number or 'unknown' or null",
    "citations": ["verbatim text extract 1"]
  }},
  "police": {{
    "present": "yes/no/not reported",
    "action_beyond_presence": "...", 
    "violence": "...",
    "citations": ["verbatim text extract 1"]
  }},
  "arrests": {{
    "reported": true/false,
    "number": "number or 'unknown'  or null"
  }},
  "protester_violence": {{
    "reported": true/false,
    "type": "null if not reported or: 1 – Weapons (rocks, bombs, guns, firebombs, bricks, stones); 2 – Physical or hand-to-hand violence; 3 – Other; 4 – Weapons and physical violence; 5 – Weapons and other; 6 – Physical and other; 7 – Weapons, physical, and other types of violence",
    "citations": ["verbatim text extract 1"]
  }},
  "property_damage": {{
    "reported" true/false,
    "euros": "amount in euros or 'unknown' or null"
  }},
  "injuries": {{
    "protesters": {{
      "reported": true/false,
      "number": "number or 'unknown' or null"
    }},
    "bystanders": {{
      "reported": true/false,
      "number": "number or 'unknown' or null"
    }},
    "police": {{
      "reported": true/false,
      "number": "number or 'unknown' or null"
    }},
    "others": {{
      "reported": true/false,
      "number": "number or 'unknown' or null",
      "who": "if mentioned"
    }}
  }},
  "deaths": {{
    "protesters": {{
      "reported": true/false,
      "number": "number or 'unknown' or null"
    }},
    "bystanders": {{
      "reported": true/false,
      "number": "number or 'unknown' or null"
    }},
    "police": {{
      "reported": true/false,
      "number": "number or 'unknown' or null"
    }},
    "others": {{
      "reported": true/false,
      "number": "number or 'unknown' or null",
      "who": "if mentioned"
    }}
  }},
  "sentiment": "positive/neutral/negative",
  "keywords": ["...", "..."]
}}

Topics: climate_environment, social_justice, racism_discrimination, anti_rightwing_extremism, rightwing_extremism,
gender_feminism, lgbtq_rights, immigration_asylum, war_peace, economic_inequality, labor_workers_rights, housing,
education, healthcare, digital_privacy, eu_politics, energy_policy, covid_health_policy, east_west_issues, other

Source types for crowd-size estimates: organizers, police, media, other, unattributed, unclear

---

**1️⃣ Protest Coverage (Climate)**
Input → 15.11.2025. Gestern veranstaltete “Fridays for Future” in Köln eine Laternendemo am Bahnhofsvorplatz. Rund 2000 Menschen, darunter primär Studierende, erschienen laut Angaben der Organisator:innen. Sie protestieren für Klimagerechtigkeit und fordern eine Einhaltung des Pariser Abkommens von der Bundesregierung.
Output →
[
  {{
    "is_protest": "yes",
    "event_date": "2025-11-14",
    "number_of_days": "1",
    "location": {{
      "square_institution": "Bahnhofsvorplatz",
      "city": "Köln",
      "bundesland": "Nordrhein-Westfalen",
      "country": "Deutschland"
    }},
    "protest_size_estimates": [
      {{
        "source_type": "organizers",
        value: "2000",
        "source_name": "'Fridays for Future'"
      }}
    ]
    "main_issue": "Klimagerechtigkeit",
    "topics": [
      {{
        "topic_name": "clime_environment",
        "confidence": "high",
        "relevance": "primary",
        "citations": ["Sie protestieren für Klimagerechtigkeit."]
      }},
      {{
        "topic_name": "social_justice",
        "confidence": "high",
        "relevance": "secondary",
        "citations": ["Sie protestieren für Klimagerechtigkeit."]
      }}
    ],
    "protest_slogan": "Fridays for Future",
    "target": "Bundesregierung",
    "organizations": ["Fridays for Future"],
    "participant_demographics": [
      {{
        "group": "Studierende",
        "citations": ["darunter primär Studierende"]
      }}
    ],
    "counterprotestors": {{
      "reported": false,
      "who": null,
      "number": null,
      "citations": null
    }},
    "police": {{
      "present": "not reported",
      "action_beyond_presence": null, 
      "violence": null,
      "citations": null
    }},
    "arrests": {{
      "reported": false,
      "number": null
    }},
    "protester_violence": {{
      "reported": false,
      "type": null
      "citations": null
    }},
    "property_damage": {{
      "reported" false,
      "euros": null
    }},
    "injuries": {{
      "protesters": {{
        "reported": false,
        "number": null
      }},
      "bystanders": {{
        "reported": false,
        "number": null
      }},
      "police": {{
        "reported": false,
        "number": null
      }},
      "others": {{
        "reported": false,
        "number": null,
        "who": null
      }}
    }},
    "deaths": {{
      "protesters": {{
        "reported": false,
        "number": null
      }},
      "bystanders": {{
        "reported": false,
        "number": null
      }},
      "police": {{
        "reported": false,
        "number": null
      }},
      "others": {{
        "reported": false,
        "number": null,
        "who": null
      }}
    }},
    "sentiment": "neutral",
    "keywords": ["Klimakrise", "Fridays for Future", "Klimademo", "Klimagerechtigkeit", "Laternen", "Köln"]
  }}
]

---

**3️⃣ Multiple Protests (Nationwide Climate Strike)**
Input → Nationwide “Fridays for Future” demos in Berlin, Hamburg, München; violence in Berlin.  
Output →
[
  {{
    "is_protest": true,
    "event_date": "2024-09-20",
    "location": {{"city": "Berlin", "bundesland": "Berlin", "country": "Deutschland"}},
    "protest_size": {{"organizer_estimate": null, "police_estimate": 15000, "primary_source": "police"}},
    "main_issue": "Klimaschutz",
    "topics": {{"primary_topic": "climate_environment", "secondary_topics": [], "confidence": "high",
       "citations": {{"climate_environment": ["Bundesweiter Klimastreik"]}}}},
    "protest_slogan": "Fridays for Future",
    "organizations": ["Fridays for Future"],
    "highlighted_notable_participation": {{"groups": ["students"], "citations": ["viele Schüler nahmen teil"]}},
    "police_response": "Einsatz von Pfefferspray",
    "violence_reported": true,
    "arrests_made": "unknown",
    "sentiment": "neutral",
    "keywords": ["Klimastreik", "Berlin"]
  }},
  {{
    "is_protest": true,
    "event_date": "2024-09-20",
    "location": {{"city": "Hamburg", "bundesland": "Hamburg", "country": "Deutschland"}},
    "protest_size": {{"organizer_estimate": 10000, "police_estimate": null, "primary_source": "organizers"}},
    "main_issue": "Klimaschutz",
    "topics": {{"primary_topic": "climate_environment", "secondary_topics": [], "confidence": "high",
       "citations": {{"climate_environment": ["Demonstration für Klimaschutz"]}}}},
    "protest_slogan": "Fridays for Future",
    "organizations": ["Fridays for Future"],
    "highlighted_notable_participation": {{"groups": ["students"], "citations": []}},
    "police_response": null,
    "violence_reported": false,
    "arrests_made": "unknown",
    "sentiment": "neutral",
    "keywords": ["Hamburg", "Klimastreik"]
  }},
  {{
    "is_protest": true,
    "event_date": "2024-09-20",
    "location": {{"city": "München", "bundesland": "Bayern", "country": "Deutschland"}},
    "protest_size": {{"organizer_estimate": null, "police_estimate": null, "primary_source": "unattributed"}},
    "main_issue": "Klimaschutz",
    "topics": {{"primary_topic": "climate_environment", "secondary_topics": [], "confidence": "high",
       "citations": {{"climate_environment": ["Kundgebung in München"]}}}},
    "protest_slogan": "Fridays for Future",
    "organizations": ["Fridays for Future"],
    "highlighted_notable_participation": {{"groups": [], "citations": []}},
    "police_response": null,
    "violence_reported": false,
    "arrests_made": "unknown",
    "sentiment": "neutral",
    "keywords": ["München", "Klimastreik"]
  }}
]

---

**1️⃣ Unclear whether event should count as protest**
Input → Public disturbance at town hall on new fracking contract. Protesters interrupt meeting with shouts.
Output →
[
  {{
    "is_protest": "unsure",
    "event_date": "YYYY-MM-DD or null",
    "number_of_days": "number for multi-day events or 1 for a single-day event",
    "location": {{"city": "...", "bundesland": "...", "country": "..."}},
    "protest_size_estimates": [{{"source_type": "...", value: "number or 'unknown'", "source_name": "..."}}, {{...}}]
    "main_issue": "...",
    "topics": [
      {{
          "topic_name": "...",
          "confidence": "high/medium/low",
          "relevance": "primary/secondary",
          "citations": ["verbatim text extract 1", "verbatim text extract 2"]
      }}
    ],
    "protest_slogan": "... or null",
    "against_whom": "...",
    "organizations": ["..."],
    "participant_demographics": [
      {{
          "group": "...",
          "citations": ["..."]
      }}
    ],
    "counterprotestors": {{
          "reported": true/false,
          "who": "...",
          "number": "number or 'unknown'",
          "citations": ["verbatim text extract 1"]
    }},
    "police": {{
      "present": "yes/no/not reported",
      "action_beyond_presence": "...", 
      "violence": "...",
      "citations": ["verbatim text extract 1"]
    }},
    "arrests": {{
      "reported": true/false,
      "number": "number or 'unknown'"
    }},
    "protester_violence": {{
      "reported": true/false,
      "type": "1 – Weapons (rocks, bombs, guns, firebombs, bricks, stones); 2 – Physical or hand-to-hand violence; 3 – Other; 4 – Weapons and physical violence; 5 – Weapons and other; 6 – Physical and other; 7 – Weapons, physical, and other types of violence",
      "citations": ["verbatim text extract 1"]
    }},
    "property_damage": {{
      "reported" true/false,
      "euros": "amount in euros or 'unknown'"
    }},
    "injuries": {{
      "protesters": {{
          "reported": true/false,
          "number": "number or 'unknown'"
      }},
      "bystanders": {{
          "reported": true/false,
          "number": "number or 'unknown'"
      }},
      "police": {{
          "reported": true/false,
          "number": "number or 'unknown'"
      }},
      "others": {{
          "reported": true/false,
          "number": "number or 'unknown'",
          "who": "if mentioned"
      }}
    }},
    "deaths": {{
      "protesters": {{
          "reported": true/false,
          "number": "number or 'unknown'"
      }},
      "bystanders": {{
          "reported": true/false,
          "number": "number or 'unknown'"
      }},
      "police": {{
          "reported": true/false,
          "number": "number or 'unknown'"
      }},
      "others": {{
          "reported": true/false,
          "number": "number or 'unknown'",
          "who": "if mentioned"
      }}
    }},
    "sentiment": "positive/neutral/negative",
    "keywords": ["...", "..."]
  }}
]

---

Return JSON only — start with [ and end with ].
