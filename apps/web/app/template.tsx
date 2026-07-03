export default function Template({ children }: { children: React.ReactNode }) {
  return (
    <div className="w-full h-full animate-in fade-in slide-in-from-bottom-2 duration-300">
      {children}
    </div>
  );
}
