package model

import "time"

type Doacao struct {
	CpfPessoa string `db:"cpf_pessoa"`
	Codigo    int
	CodigoOng int `db:"codigo_ong"`
	Tipo      string
	Valor     int
	Data      time.Time
}
