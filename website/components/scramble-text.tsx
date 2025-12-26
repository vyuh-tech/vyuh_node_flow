'use client';

import { useState, useEffect, useCallback } from 'react';

const WORDS = [
  'Data',
  'Process',
  'Agent',
  'Work',
  'Action',
  'Image',
  'Content',
  'Code',
];
const CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

export function ScrambleText() {
  const [wordIndex, setWordIndex] = useState(0);
  const [displayText, setDisplayText] = useState(WORDS[0]);
  const [isScrambling, setIsScrambling] = useState(false);

  const scramble = useCallback((targetWord: string) => {
    let iteration = 0;
    const interval = setInterval(() => {
      setDisplayText(() =>
        targetWord
          .split('')
          .map((char, index) => {
            if (index < iteration) {
              return targetWord[index];
            }
            return CHARS[Math.floor(Math.random() * CHARS.length)];
          })
          .join(''),
      );

      if (iteration >= targetWord.length) {
        clearInterval(interval);
        setIsScrambling(false);
      }

      iteration += 1 / 2;
    }, 50);
  }, []);

  useEffect(() => {
    const timeout = setTimeout(() => {
      setIsScrambling(true);
      const nextIndex = (wordIndex + 1) % WORDS.length;
      setWordIndex(nextIndex);
      scramble(WORDS[nextIndex]);
    }, 3000);

    return () => clearTimeout(timeout);
  }, [wordIndex, scramble]);

  return <span className="inline-block min-w-[4ch]">{displayText}</span>;
}
