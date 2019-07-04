package model

type Ong struct {
	Codigo                   int
	Nome                     string
	Rua                      string
	Bairro                   string
	Cep                      int
	Numero                   int
	CpfVoluntarioResponsavel string `db:"cpf_voluntario_responsavel"`
	Cidade                   string
}
