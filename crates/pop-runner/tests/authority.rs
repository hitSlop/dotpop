use pop_runner::{Error, Evaluator};
#[cfg(all(not(target_os = "ios"), feature = "in-process"))]
#[test]
fn explicit_capture_and_process_providers_keep_distinct_command_authority() {
    let capture = Evaluator::in_process_capture(std::env::current_exe().unwrap()).unwrap();
    assert!(!capture.supports_commands());
    assert!(
        Evaluator::process(std::env::current_exe().unwrap(), vec!["--evaluate-command".into()])
            .unwrap()
            .supports_commands()
    );
    assert!(capture.run(1, "", "{}").is_err(), "capture does not acquire commands from feature unification");
}

#[cfg(feature = "in-process")]
#[test]
fn in_process_commands_enforces_bounds_and_runs_authored_commands() {
    let commands = Evaluator::in_process_commands(std::env::current_exe().unwrap()).unwrap();
    assert!(commands.supports_commands());

    let bundle = r#"
        const sym = Symbol.for("pop.command-set");
        globalThis.__popCommands = {
            [sym]: {
                specs: {
                    echo: { run: (_ctx, args) => ({ ok: args.msg }) },
                    spin: { run: () => { while (true) {} } },
                    boom: { run: () => { const a = []; while (true) a.push(new Uint8Array(1024 * 1024)); } },
                }
            }
        };
    "#;
    let req = |name: &str, args: &str| {
        format!(
            r#"{{"name":"{name}","args":{args},"now":1,"seed":[1,2,3,4],"value":{{}},"descriptor":{{"kind":"object","properties":{{}}}}}}"#
        )
    };

    // 1. Happy path authored command runs cleanly in process.
    let ok = commands.run(1, bundle, &req("echo", r#"{"msg":"hi"}"#)).unwrap();
    assert!(ok.contains(r#""ok":true"#) && ok.contains(r#""hi""#), "unexpected ok output: {ok}");

    // 2. Infinite loop aborts within the cooperative 250ms deadline.
    let err = commands.run(1, bundle, &req("spin", "{}")).unwrap_err();
    assert!(matches!(err, Error::Timeout), "expected Timeout, got {err:?}");

    // 3. Memory bomb fails cleanly at the 16 MiB mobile heap cap.
    let err = commands.run(1, bundle, &req("boom", "{}")).unwrap_err();
    assert!(matches!(err, Error::Memory), "expected Memory, got {err:?}");
}
