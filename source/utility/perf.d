module perf;

struct Perf
{
    import core.time;

    static Duration[string] times;
    string fn;
    MonoTime started;
    
    @disable this();
    
    this(typeof(null), string fn = __PRETTY_FUNCTION__)
    {
        this.fn = fn;
        started = MonoTime.currTime;
    }
    
    ~this()
    {
        if(fn is null) return;
        const now = MonoTime.currTime;
        times[fn] = times.get(fn, Duration.zero) + (now - started);
    }
}