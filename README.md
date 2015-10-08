# FreeBSD Install Script for Virtualmin

## Still under active development.

Requires that you setup custom PKG repos

/usr/local/etc/pkg/repos/FreeBSD.conf

```json
FreeBSD: { enabled: no }
```

/usr/local/etc/pkg/repos/Virtualmin.conf

```json
Virtualmin: {
	url: "http://pkg.morante.net/virtualmin/${ABI}",
	enabled: yes
}
```

