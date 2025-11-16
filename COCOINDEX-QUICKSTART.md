# CocoIndex Quick Start Guide

Get started with CocoIndex integration in 15 minutes.

## Prerequisites

```bash
# Install CocoIndex
pip install cocoindex

# Install dependencies
pip install pyyaml flask
```

## Step 1: Extract Metadata (5 minutes)

```bash
# Make script executable
chmod +x scripts/cocoindex/extract_metadata.py

# Run metadata extraction
python scripts/cocoindex/extract_metadata.py
```

**Expected output:**
```
📊 Extracting metadata from knowledge base...
   - Extracting vulnerabilities...
     ✓ Found 10 vulnerabilities
   - Extracting templates...
     ✓ Found 7 templates
   - Extracting patterns...
     ✓ Found 12 patterns
   - Extracting code snippets...
     ✓ Found 5 snippet collections

✅ Metadata extraction complete!
   Output: .cocoindex/structured-metadata.json
   Total entities: 34
```

**Verify:**
```bash
cat .cocoindex/structured-metadata.json | head -20
```

## Step 2: Test Basic Search (5 minutes)

For now, let's test the concept with a simple semantic search using just Python and sentence-transformers:

```bash
pip install sentence-transformers
```

Create a test script:

```python
# test_semantic_search.py
from sentence_transformers import SentenceTransformer
import json
from pathlib import Path
import numpy as np

# Load model
model = SentenceTransformer('all-MiniLM-L6-v2')

# Load metadata
with open('.cocoindex/structured-metadata.json') as f:
    metadata = json.load(f)

# Create document corpus
documents = []
doc_ids = []

for vuln_id, vuln in metadata['entities']['vulnerabilities'].items():
    documents.append(f"{vuln['name']}: {vuln['description']}")
    doc_ids.append(('vulnerability', vuln_id, vuln['name']))

# Create embeddings
print("Creating embeddings...")
doc_embeddings = model.encode(documents)

# Query
query = "How do I prevent recursive call attacks?"
query_embedding = model.encode([query])[0]

# Find similar documents
similarities = np.dot(doc_embeddings, query_embedding)
top_indices = np.argsort(similarities)[::-1][:5]

print(f"\nSearch results for: '{query}'\n")
for i, idx in enumerate(top_indices, 1):
    score = similarities[idx]
    doc_type, doc_id, doc_name = doc_ids[idx]
    print(f"{i}. {doc_name} ({doc_type})")
    print(f"   Score: {score:.3f}")
    print(f"   ID: {doc_id}\n")
```

Run it:
```bash
python test_semantic_search.py
```

**Expected output:**
```
Search results for: 'How do I prevent recursive call attacks?'

1. Reentrancy (vulnerability)
   Score: 0.845
   ID: vuln_reentrancy

2. Unchecked Returns (vulnerability)
   Score: 0.673
   ID: vuln_unchecked_returns

3. Dos Attacks (vulnerability)
   Score: 0.621
   ID: vuln_dos_attacks
```

## Step 3: Explore the Metadata (5 minutes)

```bash
# View all vulnerabilities
python -c "
import json
with open('.cocoindex/structured-metadata.json') as f:
    data = json.load(f)

print('Vulnerabilities in Knowledge Base:\n')
for vid, vuln in data['entities']['vulnerabilities'].items():
    print(f\"  {vuln['severity']:8} - {vuln['name']}\")
    if vuln['real_exploits']:
        for exploit in vuln['real_exploits']:
            print(f\"           → {exploit['name']}: ${exploit['loss_usd']:,.0f}\")
"
```

**Expected output:**
```
Vulnerabilities in Knowledge Base:

  CRITICAL - Reentrancy
           → The DAO: $60,000,000
  CRITICAL - Access Control
           → Rubixi: $5,000,000
           → Parity Wallet: $280,000,000
  HIGH     - Integer Overflow
           → BeautyChain: $900,000,000
  ...
```

## Next Steps

### Option A: Full CocoIndex Implementation

Follow the complete implementation plan in `COCOINDEX-INTEGRATION-PLAN.md`:

```bash
# Phase 1: Foundation (Week 1-2)
- Set up CocoIndex pipeline
- Create embeddings for all documents
- Build initial index

# Phase 2: Relationships (Week 3-4)
- Extract relationships from content
- Build knowledge graph
- Test graph queries

# Phase 3: Query Interface (Week 5-6)
- Create semantic search API
- Build web UI
- Test all endpoints

# Phase 4: Integration (Week 7)
- Integrate with existing sync scripts
- Set up automated updates
- Deploy to production
```

### Option B: Incremental Approach

Start with just semantic search:

1. **Week 1:** Basic embeddings + search (what we just tested)
2. **Week 2:** Add relationship extraction for vulnerabilities
3. **Week 3:** Expand to templates and patterns
4. **Week 4:** Build simple web UI

### Option C: Use Existing Tools

If you want to get started even faster, you can use:

- **LangChain** + **Chroma** for vector search
- **NetworkX** for relationship graphs
- **Streamlit** for quick UI

Example with LangChain:
```python
from langchain.embeddings import HuggingFaceEmbeddings
from langchain.vectorstores import Chroma
from langchain.document_loaders import DirectoryLoader

# Load all markdown files
loader = DirectoryLoader('knowledge-base-action/', glob='**/*.md')
documents = loader.load()

# Create embeddings
embeddings = HuggingFaceEmbeddings()

# Create vector store
vectorstore = Chroma.from_documents(documents, embeddings)

# Query
results = vectorstore.similarity_search("How to prevent reentrancy?", k=5)

for result in results:
    print(result.page_content[:200])
```

## Troubleshooting

**Issue:** `ModuleNotFoundError: No module named 'cocoindex'`
**Solution:** CocoIndex may not be published yet. Use the GitHub version:
```bash
pip install git+https://github.com/cocoindex-io/cocoindex.git
```

**Issue:** Metadata extraction finds 0 vulnerabilities
**Solution:** Ensure you're running from the repository root:
```bash
cd /path/to/safe-smart-contracts
python scripts/cocoindex/extract_metadata.py
```

**Issue:** Want to see what CocoIndex can do before committing
**Solution:** Check out their examples: https://github.com/cocoindex-io/cocoindex/tree/main/examples

## Recommended Reading

Before full implementation, review:

1. **COCOINDEX-INTEGRATION-PLAN.md** - Complete implementation guide (this file)
2. **CocoIndex Documentation** - https://github.com/cocoindex-io/cocoindex
3. **.knowledge-base-sync/sync-config.json** - Your existing sync configuration

## Questions?

**Q: Do I need to change my existing files?**
A: No! CocoIndex reads your existing markdown and Solidity files as-is.

**Q: Will this slow down my workflows?**
A: No. CocoIndex processes files once and then incrementally updates. Queries are instant.

**Q: Can I use CocoIndex alongside my existing search.sh?**
A: Yes! They work independently. Use search.sh for simple keyword searches, CocoIndex for semantic/graph queries.

**Q: What if I only want semantic search, not the full graph?**
A: Totally fine! Start with Step 2 above and just use vector embeddings for search. That alone is a huge improvement.

---

**Next:** Read `COCOINDEX-INTEGRATION-PLAN.md` for the complete roadmap.
