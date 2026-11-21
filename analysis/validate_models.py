import random


DIRECTED = [(0x0000,0x0000),(0x0000,0xffff),(0xffff,0x0000),(0xffff,0x0001),
            (0xffff,0xffff),(0x7fff,0x0001),(0x8000,0x8000),(0x5555,0xaaaa),
            (0x1234,0x4321),(0x00ff,0x0001),(0x0fff,0x0001),(0xfffe,0x0001)]


def validate_models(models, seed, random_tests):
    rng = random.Random(seed)
    vectors = DIRECTED + [(rng.randrange(1 << 16), rng.randrange(1 << 16))
                          for _ in range(random_tests)]
    results = {}
    for model in models:
        errors = []
        error_count = 0
        executed_count = 0
        structural = model.validate()
        for index, (a, b) in enumerate(vectors):
            executed_count += 1
            actual = model.evaluate(a, b)
            expected = a + b
            if actual != expected:
                error_count += 1
                if len(errors) < 10:
                    errors.append((index, a, b, expected, actual))
        results[model.name] = {"directed": len(DIRECTED), "random": random_tests,
                               "planned_count": len(vectors),
                               "executed_count": executed_count,
                               "error_count": error_count,
                               "first_errors": errors,
                               "structural": structural}
    return results
