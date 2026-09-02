# org-logos

Logo's van op SURF aangesloten organisaties.

## Logo Gallery

A static HTML page (`index.html`) displays all organization logos in a responsive grid. The page fetches the organization list from `orgs.csv` and loads logos from the `128x128/` folder.

### Features
- **Responsive design**: Works on desktop, tablet, and mobile devices
- **Lazy loading**: Images load only when needed for better performance
- **Graceful degradation**: Missing logos show a "Logo unavailable" placeholder
- **Error handling**: Clear messages for access denied (401/403) and network errors
- **Accessibility**: Proper ARIA labels and semantic HTML

### Deployment

The page is designed for GitHub Pages deployment:

1. Push changes to the repository
2. Enable GitHub Pages in repository settings (Settings → Pages → Source: main branch)
3. Access the page at `https://<username>.github.io/org-logos/`

The page works with both public and private repositories. For private repositories, users must be signed in to GitHub to view the organization list.

### Local Testing

To test locally:

```bash
# Start a local HTTP server
python3 -m http.server 8765

# Open in browser
open http://localhost:8765/index.html
```

### Data Source

The page reads organization data from `orgs.csv`, which contains:
- `crm_guid`: Unique identifier for the organization
- `crm_code`: Organization code
- `crm_name`: Organization name
- `crm_doelgroep`: Target group
- `crm_locatietype`: Location type

Currently, 330 organizations are listed, with logos available for approximately 200 of them. Missing logos gracefully display a placeholder.

---

## Logo Submission Guidelines

Belangrijk! Let op de onderstaande eigenschappen bij wijzigingen.

### Eigenschappen logo's
* Zijn vierkant
* Minstens 200x200
* Zoveel mogelijk vrij van artefacten

### Bestandsnaam

Logo wordt opgeslagen onder `<institution_guid>.png` in the appropriate size folder (`64x64/`, `128x128/`, or `200x200/`).

### Bronnen
* Haal het juiste logo van de sociale media accounts van de instelling.
  Hier hebben ze lang over nagedacht wat de juiste versie van het logo
  is.
* Linkedin is een goed startpunt. Maar de bestandskwaliteit op Facebook
  of Mastodon is dikwijls beter.
