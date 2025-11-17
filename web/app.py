#!/usr/bin/env python3
"""
Safe Smart Contracts - Web Frontend
Flask application for knowledge graph queries and contract generation
"""

from flask import Flask, render_template, request, jsonify, send_file
import sys
import os
from pathlib import Path
import json
import subprocess

# Add scripts directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../scripts/cocoindex'))

from knowledge_graph import KnowledgeGraph
from contract_builder_v2 import EnhancedContractBuilder

app = Flask(__name__)
app.config['SECRET_KEY'] = 'safe-smart-contracts-2025'

# Initialize knowledge graph
kg = KnowledgeGraph()

@app.route('/')
def index():
    """Home page"""
    stats = kg.get_statistics()
    return render_template('index.html', stats=stats)

@app.route('/search')
def search_page():
    """Search interface"""
    return render_template('search.html')

@app.route('/generate')
def generate_page():
    """Contract generation interface"""
    return render_template('generate.html')

@app.route('/explore')
def explore_page():
    """Knowledge base explorer"""
    return render_template('explore.html')

@app.route('/docs')
def docs_page():
    """Documentation viewer"""
    return render_template('docs.html')

# === API ENDPOINTS ===

@app.route('/api/search', methods=['POST'])
def api_search():
    """Search the knowledge graph"""
    data = request.get_json()
    query = data.get('query', '')
    limit = data.get('limit', 10)

    try:
        results = kg.search(query, limit=limit)
        # Convert to JSON-serializable format
        formatted_results = []
        for r in results:
            formatted_results.append({
                'id': r['id'],
                'type': r['type'],
                'name': r['name'],
                'kb_source': r['kb_source'],
                'file_path': r['file_path'],
                'data': json.loads(r['data']) if r['data'] else {}
            })
        return jsonify({'success': True, 'results': formatted_results})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/vulnerabilities', methods=['GET'])
def api_vulnerabilities():
    """Get all vulnerabilities"""
    severity = request.args.get('severity')
    min_loss = request.args.get('min_loss', type=float)

    try:
        results = kg.find_vulnerabilities(severity=severity, min_loss=min_loss)
        formatted_results = []
        for v in results:
            data = json.loads(v['data'])
            formatted_results.append({
                'id': v['id'],
                'name': v['name'],
                'severity': data.get('severity', 'unknown'),
                'file_path': v['file_path'],
                'loss': data.get('historical_losses_usd', 0)
            })
        return jsonify({'success': True, 'results': formatted_results})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/templates', methods=['GET'])
def api_templates():
    """Get all templates"""
    try:
        results = kg.find_by_type('Template')
        formatted_results = []
        for t in results:
            data = json.loads(t['data'])
            formatted_results.append({
                'id': t['id'],
                'name': t['name'],
                'type': data.get('contract_type', 'unknown'),
                'lines': data.get('lines_of_code', 0),
                'file_path': t['file_path']
            })
        return jsonify({'success': True, 'results': formatted_results})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/statistics', methods=['GET'])
def api_statistics():
    """Get graph statistics"""
    try:
        stats = kg.get_statistics()
        return jsonify({'success': True, 'stats': stats})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/generate', methods=['POST'])
def api_generate():
    """Generate a smart contract"""
    data = request.get_json()

    contract_type = data.get('type')
    domain = data.get('domain')
    features = data.get('features', '')

    if not contract_type or not domain:
        return jsonify({'success': False, 'error': 'Missing required fields'})

    try:
        # Create temporary argument object
        class Args:
            pass

        args = Args()
        args.type = contract_type
        args.domain = domain
        args.features = features
        args.output = f'web/generated/{domain}/{contract_type.lower()}/'

        # Create output directory
        output_path = Path(args.output)
        output_path.mkdir(parents=True, exist_ok=True)

        # Generate contract
        builder = EnhancedContractBuilder()

        # Generate contract code
        contract_code = builder.generate_contract_with_kg(args)

        # Generate tests
        test_code = builder.generate_tests(contract_code, args)

        # Generate checklist
        checklist = builder.generate_deployment_checklist(args)

        # Get insights for deployment guide
        insights = builder._query_knowledge_graph(args)
        deployment_guide = builder.generate_deployment_guide(args, insights)

        # Save files
        contract_file = output_path / f"Secure{contract_type}Contract.sol"
        test_file = output_path / f"Secure{contract_type}Test.sol"
        checklist_file = output_path / "PRE_DEPLOYMENT_CHECKLIST.md"
        guide_file = output_path / "DEPLOYMENT_GUIDE.md"

        contract_file.write_text(contract_code)
        test_file.write_text(test_code)
        checklist_file.write_text(checklist)
        guide_file.write_text(deployment_guide)

        builder.close()

        return jsonify({
            'success': True,
            'files': {
                'contract': str(contract_file),
                'test': str(test_file),
                'checklist': str(checklist_file),
                'guide': str(guide_file)
            },
            'preview': contract_code[:500] + '...'
        })

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/file/<path:filepath>')
def api_get_file(filepath):
    """Get file contents"""
    try:
        file_path = Path(filepath)
        if file_path.exists():
            content = file_path.read_text()
            return jsonify({'success': True, 'content': content})
        else:
            return jsonify({'success': False, 'error': 'File not found'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/deepdives', methods=['GET'])
def api_deepdives():
    """Get all deep dives"""
    try:
        results = kg.find_by_type('DeepDive')
        formatted_results = []
        for dd in results:
            data = json.loads(dd['data'])
            formatted_results.append({
                'id': dd['id'],
                'name': dd['name'],
                'protocol': data.get('protocol', 'unknown'),
                'words': data.get('word_count', 0),
                'file_path': dd['file_path']
            })
        return jsonify({'success': True, 'results': formatted_results})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/integrations', methods=['GET'])
def api_integrations():
    """Get all integrations"""
    try:
        results = kg.find_by_type('Integration')
        formatted_results = []
        for i in results:
            data = json.loads(i['data'])
            formatted_results.append({
                'id': i['id'],
                'name': i['name'],
                'protocol': data.get('protocol', 'unknown'),
                'file_path': i['file_path']
            })
        return jsonify({'success': True, 'results': formatted_results})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/relationships/<node_id>', methods=['GET'])
def api_relationships(node_id):
    """Get all relationships for a node"""
    try:
        # Get the node info
        cursor = kg.conn.execute("SELECT * FROM nodes WHERE id = ?", (node_id,))
        node = cursor.fetchone()

        if not node:
            return jsonify({'success': False, 'error': 'Node not found'})

        # Get outgoing relationships
        cursor = kg.conn.execute("""
            SELECT e.relationship_type, e.properties, n.id, n.name, n.type
            FROM edges e
            JOIN nodes n ON e.target_id = n.id
            WHERE e.source_id = ?
            ORDER BY e.relationship_type
        """, (node_id,))
        outgoing = []
        for row in cursor.fetchall():
            outgoing.append({
                'relationship': row['relationship_type'],
                'target_id': row['id'],
                'target_name': row['name'],
                'target_type': row['type'],
                'properties': json.loads(row['properties']) if row['properties'] else {}
            })

        # Get incoming relationships
        cursor = kg.conn.execute("""
            SELECT e.relationship_type, e.properties, n.id, n.name, n.type
            FROM edges e
            JOIN nodes n ON e.source_id = n.id
            WHERE e.target_id = ?
            ORDER BY e.relationship_type
        """, (node_id,))
        incoming = []
        for row in cursor.fetchall():
            incoming.append({
                'relationship': row['relationship_type'],
                'source_id': row['id'],
                'source_name': row['name'],
                'source_type': row['type'],
                'properties': json.loads(row['properties']) if row['properties'] else {}
            })

        return jsonify({
            'success': True,
            'node': {
                'id': node['id'],
                'name': node['name'],
                'type': node['type'],
                'kb_source': node['kb_source'],
                'file_path': node['file_path']
            },
            'outgoing': outgoing,
            'incoming': incoming,
            'total_connections': len(outgoing) + len(incoming)
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/graph')
def graph_page():
    """Graph visualization page"""
    return render_template('graph.html')

@app.route('/api/graph/all', methods=['GET'])
def api_graph_all():
    """Get all nodes and edges for visualization"""
    try:
        # Get all nodes
        cursor = kg.conn.execute("SELECT id, name, type, kb_source FROM nodes")
        nodes = []
        for row in cursor.fetchall():
            nodes.append({
                'id': row['id'],
                'name': row['name'],
                'type': row['type'],
                'kb_source': row['kb_source']
            })

        # Get all edges
        cursor = kg.conn.execute("""
            SELECT source_id, target_id, relationship_type, properties
            FROM edges
        """)
        edges = []
        for row in cursor.fetchall():
            edges.append({
                'source': row['source_id'],
                'target': row['target_id'],
                'type': row['relationship_type'],
                'properties': json.loads(row['properties']) if row['properties'] else {}
            })

        return jsonify({
            'success': True,
            'nodes': nodes,
            'edges': edges,
            'stats': {
                'total_nodes': len(nodes),
                'total_edges': len(edges)
            }
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

if __name__ == '__main__':
    print("="*80)
    print("🌐 Safe Smart Contracts - Web Interface")
    print("="*80)
    print()
    print("Starting server...")
    print("Access at: http://localhost:8000")
    print()
    print("Features:")
    print("  • Knowledge Graph Search")
    print("  • Contract Generation")
    print("  • Knowledge Base Explorer")
    print("  • Statistics Dashboard")
    print()

    app.run(debug=True, host='0.0.0.0', port=8000)
