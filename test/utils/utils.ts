export const prettyNum = (_n: number | string) => {
    const n = _n.toString();
    let s = "";
    for (let i = 0; i < n.length; i++) {
        if (i != 0 && i % 3 == 0) {
            s = "_" + s;
        }

        s = n[n.length - 1 - i] + s;
    };

    return s;
}