'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { TokenBadge } from './TokenBadge';
import { Network } from 'lucide-react';

interface TokenNode {
  token: string;
  role: 'student' | 'alumni';
  name: string;
}

export function TokenGraph({ currentToken, lineageSuffix }: { currentToken: string; lineageSuffix: string }) {
  // Mock data generator for the graph
  const generateLineage = () => {
    const nodes: TokenNode[] = [];
    const currentYear = parseInt(currentToken.substring(0, 2));
    for (let i = currentYear - 3; i <= currentYear + 1; i++) {
      if (i > 26) continue;
      nodes.push({
        token: `${i}MX${lineageSuffix}`,
        role: i < 24 ? 'alumni' : 'student',
        name: i === currentYear ? 'You' : `Generation ${i}`,
      });
    }
    return nodes;
  };

  const nodes = generateLineage();

  return (
    <div className="psgmx-glass p-8 w-full relative overflow-hidden">
      {/* Background glow */}
      <div className="absolute -top-24 -right-24 w-64 h-64 bg-primary-purple/20 rounded-full blur-[80px] pointer-events-none" />

      <div className="flex items-center gap-3 mb-8 relative z-10">
        <div className="p-3 rounded-xl bg-primary-purple/20 border border-primary-purple/30 text-primary-purple shadow-[0_0_15px_rgba(108,61,255,0.3)]">
          <Network className="w-5 h-5" />
        </div>
        <div>
          <h3 className="psgmx-title text-xl">Token Lineage</h3>
          <p className="psgmx-subtitle mt-1">Network Suffix: {lineageSuffix}</p>
        </div>
      </div>

      <div className="flex flex-col items-center gap-2 relative z-10">
        {nodes.map((node, i) => (
          <React.Fragment key={node.token}>
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.1, type: "spring", stiffness: 100 }}
              className={`w-full max-w-sm psgmx-glass-panel p-4 flex items-center justify-between transition-all duration-300 hover:border-primary-purple/40 hover:bg-primary-purple/5 ${node.token === currentToken ? 'border-primary-purple/50 bg-primary-purple/10 shadow-[0_0_20px_rgba(108,61,255,0.15)]' : ''}`}
            >
              <div>
                <p className="text-sm font-semibold text-white flex items-center gap-2">
                  {node.name}
                  {node.token === currentToken && (
                    <span className="text-[10px] uppercase tracking-wider bg-primary-purple text-white px-1.5 py-0.5 rounded">Active</span>
                  )}
                </p>
                <p className="text-xs text-text-muted mt-1 uppercase tracking-widest">{node.role}</p>
              </div>
              <TokenBadge token={node.token} />
            </motion.div>
            
            {i < nodes.length - 1 && (
              <motion.div 
                initial={{ opacity: 0, height: 0 }}
                animate={{ opacity: 1, height: 24 }}
                transition={{ delay: i * 0.1 + 0.1 }}
                className="w-px bg-gradient-to-b from-primary-purple/50 to-electric-blue/50 relative"
              >
                <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-1.5 h-1.5 rounded-full bg-electric-blue shadow-[0_0_10px_#00F0FF] animate-pulse" />
              </motion.div>
            )}
          </React.Fragment>
        ))}
      </div>
    </div>
  );
}
