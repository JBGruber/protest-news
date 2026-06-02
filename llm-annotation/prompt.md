# Annotation Task: Protest Event Extraction

## Task Overview

You are extracting structured protest data from German news articles. Return a JSON object with a `protests` array. Each distinct protest event = one object in the array. If the article contains no protest, return `{"protests": []}`.

Return only valid JSON. No explanations outside the JSON.

## What counts as one protest vs. multiple

Treat simultaneous events by the same organization on the same issue as **one protest** even if they span multiple cities — use the `locations` array to list all cities. Create a **separate protest object** only when events differ in date, organizing group, or central issue.

## Schema

```json
{
  "protests": [
    {
      "is_protest": "yes/unsure",
      "event_date": "YYYY-MM-DD or null",
      "number_of_days": 1,
      "locations": [
        {
          "square_institution": "name of specific venue/square or null",
          "city": "...",
          "bundesland": "...",
          "country": "..."
        }
      ],
      "protest_size_estimates": [
        {
          "source_type": "organizers|police|media|other|unattributed|unclear",
          "text": "how the number appears in the article, e.g. 'rund 2000' or 'Hunderte'",
          "numerical_value": "conservative number (dozens→24, hundreds→200, thousands→2000) or 'unknown'",
          "source_name": "name of specific source, e.g. 'Polizei München', or null",
          "city": "city this estimate refers to, or null if it applies to the whole event"
        }
      ],
      "main_issue": "brief description of the central demand or grievance",
      "topics": [
        {
          "topic_name": "see topic list below",
          "confidence": "high/medium/low",
          "relevance": "primary/secondary",
          "citations": ["verbatim quote from article"]
        }
      ],
      "protest_slogan": "main slogan or null",
      "target": "who or what the protest is directed at",
      "organizations": ["organizing groups"],
      "participant_demographics": [
        {
          "group": "description of demographic group",
          "citations": ["verbatim quote from article"]
        }
      ],
      "counterprotestors": {
        "reported": true/false,
        "who": "description or null",
        "number": "number, 'unknown', or null",
        "citations": ["verbatim quote"] or null
      },
      "police": {
        "present": "yes/no/not reported",
        "action_beyond_presence": "description of actions or null",
        "violence": "description or null",
        "citations": ["verbatim quote"] or null
      },
      "arrests": {
        "reported": true/false,
        "number": "number, 'unknown', or null"
      },
      "protester_violence": {
        "reported": true/false,
        "type": "null or: 1–Weapons; 2–Physical; 3–Other; 4–Weapons+Physical; 5–Weapons+Other; 6–Physical+Other; 7–All three",
        "citations": ["verbatim quote"] or null
      },
      "property_damage": {
        "reported": true/false,
        "euros": "amount or 'unknown' or null"
      },
      "injuries": {
        "protesters": {"reported": true/false, "number": "number, 'unknown', or null"},
        "bystanders": {"reported": true/false, "number": "number, 'unknown', or null"},
        "police": {"reported": true/false, "number": "number, 'unknown', or null"},
        "others": {"reported": true/false, "number": "number, 'unknown', or null", "who": "description or null"}
      },
      "deaths": {
        "protesters": {"reported": true/false, "number": "number, 'unknown', or null"},
        "bystanders": {"reported": true/false, "number": "number, 'unknown', or null"},
        "police": {"reported": true/false, "number": "number, 'unknown', or null"},
        "others": {"reported": true/false, "number": "number, 'unknown', or null", "who": "description or null"}
      },
      "sentiment": "positive/neutral/negative",
      "keywords": ["keyword1", "keyword2"]
    }
  ]
}
```

## Topics

climate_environment, social_justice, racism_discrimination, anti_rightwing_extremism, rightwing_extremism,
gender_feminism, lgbtq_rights, immigration_asylum, war_peace, economic_inequality, labor_workers_rights, housing,
education, healthcare, digital_privacy, eu_politics, energy_policy, covid_health_policy, east_west_issues, other

## Coding Guidelines

**is_protest**: Use `"yes"` for clear demonstrations, marches, rallies, strikes, or blockades. Use `"unsure"` for ambiguous events (e.g., disruptions at public meetings, spontaneous gatherings without clear protest character).

**event_date**: Derive from the publication date and temporal references (e.g., "gestern" relative to the article date).

**numerical_value**: Use the most conservative reading — "ein paar Dutzend" → 24, "Hunderte" → 200, "Tausende" → 2000, "Zehntausende" → 20000.

**topics**: Assign `"primary"` to the one central issue and `"secondary"` to any clearly related issues. Omit topics that are merely implied or tangential.

**sentiment**: How the article frames the protest — `"positive"` (sympathetic tone), `"negative"` (threatening or dismissive tone), `"neutral"` (factual reporting without clear framing).

## Examples

**Example 1 — Single-city protest**

Input:

Article Title: Klimademo in Köln  
Publication Date: 2025-11-15  
Article Text: Gestern veranstaltete "Fridays for Future" in Köln eine Laternendemo am Bahnhofsvorplatz. Rund 2000 Menschen, darunter primär Studierende, erschienen laut Angaben der Organisator:innen. Sie protestieren für Klimagerechtigkeit und fordern eine Einhaltung des Pariser Abkommens von der Bundesregierung.

Output:

```json
{
  "protests": [
    {
      "is_protest": "yes",
      "event_date": "2025-11-14",
      "number_of_days": 1,
      "locations": [
        {
          "square_institution": "Bahnhofsvorplatz",
          "city": "Köln",
          "bundesland": "Nordrhein-Westfalen",
          "country": "Deutschland"
        }
      ],
      "protest_size_estimates": [
        {
          "source_type": "organizers",
          "text": "rund 2000",
          "numerical_value": 2000,
          "source_name": "Fridays for Future",
          "city": null
        }
      ],
      "main_issue": "Klimagerechtigkeit und Einhaltung des Pariser Abkommens",
      "topics": [
        {
          "topic_name": "climate_environment",
          "confidence": "high",
          "relevance": "primary",
          "citations": ["Sie protestieren für Klimagerechtigkeit und fordern eine Einhaltung des Pariser Abkommens"]
        }
      ],
      "protest_slogan": null,
      "target": "Bundesregierung",
      "organizations": ["Fridays for Future"],
      "participant_demographics": [
        {"group": "Studierende", "citations": ["darunter primär Studierende"]}
      ],
      "counterprotestors": {"reported": false, "who": null, "number": null, "citations": null},
      "police": {"present": "not reported", "action_beyond_presence": null, "violence": null, "citations": null},
      "arrests": {"reported": false, "number": null},
      "protester_violence": {"reported": false, "type": null, "citations": null},
      "property_damage": {"reported": false, "euros": null},
      "injuries": {
        "protesters": {"reported": false, "number": null},
        "bystanders": {"reported": false, "number": null},
        "police": {"reported": false, "number": null},
        "others": {"reported": false, "number": null, "who": null}
      },
      "deaths": {
        "protesters": {"reported": false, "number": null},
        "bystanders": {"reported": false, "number": null},
        "police": {"reported": false, "number": null},
        "others": {"reported": false, "number": null, "who": null}
      },
      "sentiment": "neutral",
      "keywords": ["Klimagerechtigkeit", "Fridays for Future", "Laternendemo", "Köln", "Pariser Abkommen"]
    }
  ]
}
```

**Example 2 — Nationwide strike (same protest, multiple cities)**

Input:

Article Title: Bundesweiter Klimastreik  
Publication Date: 2024-09-21  
Article Text: Am gestrigen Freitag gingen bundesweit Zehntausende auf die Straße. In Berlin versammelten sich laut Polizei 15.000 Menschen am Brandenburger Tor, in Hamburg zählten die Veranstalter 10.000 Teilnehmer. In München fand ebenfalls eine Kundgebung statt. Organisiert wurde der Streik von "Fridays for Future". In Berlin kam es vereinzelt zu Auseinandersetzungen mit der Polizei.

Output:

```json
{
  "protests": [
    {
      "is_protest": "yes",
      "event_date": "2024-09-20",
      "number_of_days": 1,
      "locations": [
        {"square_institution": "Brandenburger Tor", "city": "Berlin", "bundesland": "Berlin", "country": "Deutschland"},
        {"square_institution": null, "city": "Hamburg", "bundesland": "Hamburg", "country": "Deutschland"},
        {"square_institution": null, "city": "München", "bundesland": "Bayern", "country": "Deutschland"}
      ],
      "protest_size_estimates": [
        {
          "source_type": "police",
          "text": "15.000",
          "numerical_value": 15000,
          "source_name": "Polizei Berlin",
          "city": "Berlin"
        },
        {
          "source_type": "organizers",
          "text": "10.000",
          "numerical_value": 10000,
          "source_name": "Fridays for Future",
          "city": "Hamburg"
        },
        {
          "source_type": "unattributed",
          "text": "Zehntausende",
          "numerical_value": 20000,
          "source_name": null,
          "city": null
        }
      ],
      "main_issue": "Klimaschutz",
      "topics": [
        {
          "topic_name": "climate_environment",
          "confidence": "high",
          "relevance": "primary",
          "citations": ["Bundesweiter Klimastreik"]
        }
      ],
      "protest_slogan": "Fridays for Future",
      "target": null,
      "organizations": ["Fridays for Future"],
      "participant_demographics": [],
      "counterprotestors": {"reported": false, "who": null, "number": null, "citations": null},
      "police": {
        "present": "yes",
        "action_beyond_presence": "Auseinandersetzungen mit der Polizei in Berlin",
        "violence": "vereinzelt zu Auseinandersetzungen",
        "citations": ["In Berlin kam es vereinzelt zu Auseinandersetzungen mit der Polizei"]
      },
      "arrests": {"reported": false, "number": null},
      "protester_violence": {"reported": false, "type": null, "citations": null},
      "property_damage": {"reported": false, "euros": null},
      "injuries": {
        "protesters": {"reported": false, "number": null},
        "bystanders": {"reported": false, "number": null},
        "police": {"reported": false, "number": null},
        "others": {"reported": false, "number": null, "who": null}
      },
      "deaths": {
        "protesters": {"reported": false, "number": null},
        "bystanders": {"reported": false, "number": null},
        "police": {"reported": false, "number": null},
        "others": {"reported": false, "number": null, "who": null}
      },
      "sentiment": "neutral",
      "keywords": ["Klimastreik", "Fridays for Future", "Berlin", "Hamburg", "München"]
    }
  ]
}
```

## Now Extract the Protests

Please read the article carefully and return your extraction in the JSON format specified above.
