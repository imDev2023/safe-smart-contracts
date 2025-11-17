# Safe Smart Contracts - Web Interface

Beautiful web interface for the Safe Smart Contracts knowledge graph and contract generation system.

## Features

🔍 **Knowledge Base Search**
- Full-text search across 284 KB files
- Filter by type (Vulnerabilities, Templates, Deep Dives, Integrations)
- Filter by severity, loss amount, protocol
- Real-time results with syntax highlighting

🏗️ **Contract Generation**
- Interactive form-based interface
- 4 domains: DeFi, Gaming, NFT, AI
- 12 features across all domains
- Live preview of generated contracts
- Download all files (contract, tests, guides)

📊 **Knowledge Explorer**
- Browse by category
- View all vulnerabilities, templates, deep dives
- Statistics dashboard
- Relationship visualization

📚 **Documentation**
- Complete usage guide
- API reference
- Command-line examples
- Domain guides

## Installation

```bash
# Install dependencies
pip install -r requirements.txt

# Run the web server
python app.py
```

## Usage

1. **Start the server:**
   ```bash
   python app.py
   ```

2. **Open your browser:**
   ```
   http://localhost:5000
   ```

3. **Navigate the interface:**
   - **Home** - Overview and statistics
   - **Search** - Query the knowledge graph
   - **Generate** - Create smart contracts
   - **Explore** - Browse by category
   - **Docs** - Read documentation

## Pages

### Home (`/`)
- Statistics dashboard
- Feature overview
- Quick start guide
- Node distribution

### Search (`/search`)
- Full-text search
- Quick filters (Vulnerabilities, Templates, etc.)
- Advanced filtering
- Live results

### Generate (`/generate`)
- Contract type selection (ERC20, ERC721)
- Domain selection (DeFi, Gaming, NFT, AI)
- Feature checkboxes
- One-click generation
- Code preview
- File download

### Explore (`/explore`)
- Browse all vulnerabilities
- Browse all templates
- Browse all deep dives
- Browse all integrations

### Docs (`/docs`)
- Complete documentation
- API reference
- Usage examples
- Command-line guides

## API Endpoints

### Search
```bash
POST /api/search
Body: {"query": "reentrancy", "limit": 10}
```

### Vulnerabilities
```bash
GET /api/vulnerabilities?severity=high&min_loss=50000000
```

### Templates
```bash
GET /api/templates
```

### Generate Contract
```bash
POST /api/generate
Body: {
  "type": "ERC721",
  "domain": "gaming",
  "features": "vrf,achievements,anti-cheat"
}
```

### Statistics
```bash
GET /api/statistics
```

## Tech Stack

**Backend:**
- Flask 3.0 (Python web framework)
- SQLite (Knowledge graph database)
- Custom knowledge graph engine

**Frontend:**
- Bootstrap 5.3 (UI framework)
- Font Awesome 6.4 (Icons)
- Prism.js (Code highlighting)
- Vanilla JavaScript (Interactivity)

## File Structure

```
web/
├── app.py                  # Flask application
├── requirements.txt        # Python dependencies
├── README.md              # This file
├── templates/
│   ├── base.html          # Base template
│   ├── index.html         # Home page
│   ├── search.html        # Search interface
│   ├── generate.html      # Contract generation
│   ├── explore.html       # KB explorer
│   └── docs.html          # Documentation
└── generated/             # Output directory
    ├── defi/
    ├── gaming/
    ├── nft/
    └── ai/
```

## Features by Domain

### DeFi
- ✅ Anti-sniper bot detection
- ✅ Slippage protection
- ✅ Chainlink oracle integration
- ✅ Buy/wallet limits
- ✅ Trading controls

### Gaming
- ✅ Chainlink VRF (randomness)
- ✅ Achievement system
- ✅ Anti-cheat protection
- ✅ Player progression tracking

### NFT
- ✅ ERC2981 royalties
- ✅ Metadata reveal system
- ✅ Merkle tree allowlist
- ✅ Batch minting

### AI
- ✅ Chainlink Functions
- ✅ Usage metering
- ✅ Payment splits
- ✅ Credit system

## Development

```bash
# Run in development mode
python app.py

# The server will auto-reload on file changes
# Access at http://localhost:5000
```

## Production Deployment

For production deployment, use a WSGI server:

```bash
# Install gunicorn
pip install gunicorn

# Run with gunicorn
gunicorn -w 4 -b 0.0.0.0:5000 app:app
```

Or use Nginx + uWSGI:

```bash
# Install uwsgi
pip install uwsgi

# Run with uwsgi
uwsgi --http :5000 --wsgi-file app.py --callable app
```

## Screenshots

### Home Page
- Statistics dashboard
- Feature cards
- Quick start

### Search Page
- Search box
- Quick filters
- Live results with KB references

### Generate Page
- Interactive form
- Domain selection
- Feature checkboxes
- Live preview

### Explore Page
- Category browsing
- Filter by type
- View details

## API Examples

### JavaScript
```javascript
// Search
fetch('/api/search', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({query: 'reentrancy', limit: 10})
})
.then(r => r.json())
.then(data => console.log(data.results));

// Generate
fetch('/api/generate', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({
    type: 'ERC721',
    domain: 'gaming',
    features: 'vrf,achievements'
  })
})
.then(r => r.json())
.then(data => console.log(data.files));
```

### Python
```python
import requests

# Search
response = requests.post('http://localhost:5000/api/search',
  json={'query': 'reentrancy', 'limit': 10})
results = response.json()['results']

# Generate
response = requests.post('http://localhost:5000/api/generate',
  json={
    'type': 'ERC721',
    'domain': 'gaming',
    'features': 'vrf,achievements'
  })
files = response.json()['files']
```

### curl
```bash
# Search
curl -X POST http://localhost:5000/api/search \
  -H "Content-Type: application/json" \
  -d '{"query": "reentrancy", "limit": 10}'

# Generate
curl -X POST http://localhost:5000/api/generate \
  -H "Content-Type: application/json" \
  -d '{"type": "ERC721", "domain": "gaming", "features": "vrf,achievements"}'
```

## Troubleshooting

**Port already in use:**
```bash
# Change port in app.py:
app.run(debug=True, host='0.0.0.0', port=8000)
```

**Knowledge graph not found:**
```bash
# Rebuild the knowledge graph
cd ..
python scripts/cocoindex/knowledge_graph.py
```

**Generated files not showing:**
```bash
# Check output directory
ls -la web/generated/
```

## Contributing

To add new features:

1. Add API endpoint in `app.py`
2. Create/update template in `templates/`
3. Add JavaScript handlers
4. Update documentation

## License

Same as parent repository

## Support

For issues or questions:
- Check `KNOWLEDGE-GRAPH-INTEGRATION.md`
- Review `CONTRACT-GENERATOR-README.md`
- See `DOMAIN-EXAMPLES.md`

---

**Built with ❤️ using Flask + Bootstrap + Knowledge Graph**

**Total**: 284 KB files, 45 graph nodes, 16 relationships, 4 domains, 12 features
