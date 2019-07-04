package model

import "time"

type LogBeneficiario struct {
	Id              int
	CpfBeneficiario string `db:"cpf_beneficiario"`
	Acao            string
	Data            time.Time
}
