#!/bin/bash
#
# Start the Safe Smart Contracts Web Interface
#

echo "================================================================================"
echo "🌐 Safe Smart Contracts - Web Interface"
echo "================================================================================"
echo ""
echo "Starting web server..."
echo ""
echo "📊 Features:"
echo "  • Knowledge Graph Search"
echo "  • Contract Generation"
echo "  • Knowledge Base Explorer"
echo "  • Statistics Dashboard"
echo ""
echo "🌍 Server will start at: http://localhost:5000"
echo ""
echo "Press Ctrl+C to stop the server"
echo "================================================================================"
echo ""

cd web && python app.py
