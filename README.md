# Protest News Databas
## Motivation

Datasets of protest events are of great value when studying movements or the reactions they evoke in media a politics.
This repo is the attempt to combine different open source tools in a pipeline that combines web-scraping and AI-based data extraction.

![Pipeline](pipeline.svg)

In words, the pipeline consists of these parts (in the order in which information enters the database):

1. [FreshRSS](https://freshrss.org/) collects articles published in one of 71 German newspapers (currently) 
1.5. Articles are filtered for protest news and copied from the FreshRSS databse to the [AmCAT](https://amcat.nl/) database
2. [paperboy](https://jbgruber.github.io/paperboy/) scrapes full texts of the articles
3. Using an LLM (currently [qwen3.5:9b](https://huggingface.co/Qwen/Qwen3.5-9B)) via [rollama](https://jbgruber.github.io/rollama/) we extract structured information

The dataset (except for the full texts of the articles) is available at <https://protest.jbgruber.online/projects/de-news>{target="_blank"}.

## Running it yourself

1. Clone this repo
2. Create directories to store data (you can move these wherever you want, but they need to match the `docker-compose.yml`):

```bash
mkdir -p ./data/{freshrss-app,freshrss-extensions,freshrss-db,elastic-amcat4,elastic-amcat4-snapshots}
```

3. Make sure you have Ollama running (see e.g., <https://jbgruber.github.io/rollama/#installation>)
4. Spin up the full stack via `docker compose up -d`


This runs all parts on a single computer.
It is also possible to run, for example, the LLM part elsewhere.

