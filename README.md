## Protest News

1. Pull RSS from News sites that are supported by paperboy via
freshrss
2. Copy News articles to AmCAT
3. Container running paperboy checks out unpopulated articles and fetches full texts and updates AmCAT entries
4. Container running rollama annotates full texts and update AmCAT entries

## Setup

1. Clone this repo
2. Create directories to store data (you can move these wherever you want, but they need to match the `docker-compose.yml`)b

```bash
mkdir -p ./data/{freshrss-app,freshrss-extensions,freshrss-db,elastic-amcat4,elastic-amcat4-snapshots}
```