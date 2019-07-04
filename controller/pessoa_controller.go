package controller

import (
	"errors"
	"projeto_bd/model"

	"github.com/jmoiron/sqlx"
	"github.com/labstack/echo"
	_ "github.com/lib/pq"
)

type pessoaController struct {
	conn *sqlx.DB
}

func NewPessoaController() *pessoaController {
	p := new(pessoaController)
	var err error
	p.conn, err = sqlx.Connect("postgres", "postgres://root@localhost:5432/trabalho?sslmode=disable")
	if err != nil {
		println("Falha ao conectar: " + err.Error())
		return nil
	}
	return p
}
func (p *pessoaController) Get(c echo.Context) error {
	cpf := c.Param("cpf")
	if cpf == "" {
		pessoas := []model.Pessoa{}
		err := p.conn.Select(&pessoas, "select * from pessoa")
		if err != nil {
			println("Falha ao buscar pessoa: " + err.Error())
			return nil
		}
		c.JSON(200, pessoas)

	} else {
		pessoa := model.Pessoa{Cpf: cpf}
		err := p.conn.Get(&pessoa, "select * from pessoa where cpf=$1", cpf)
		if err != nil {
			println("Falha ao buscar pessoa: " + err.Error())
			return nil
		}
		c.JSON(200, pessoa)
	}
	return nil
}
func (p *pessoaController) Put(c echo.Context) error {

	pessoa := new(model.Pessoa)
	err := c.Bind(pessoa)
	if err != nil {
		println("Falha ao dar parse na pessoa: " + err.Error())
		return nil
	}

	_, err = p.conn.Exec("UPDATE pessoa"+
		"set nome = $1,"+
		"rua = $2,"+
		"bairro = $3,"+
		"cidade = $4,"+
		"cep = $5,"+
		"telefone=$6"+
		"where cpf=$7",
		pessoa.Nome, pessoa.Rua, pessoa.Bairro, pessoa.Cidade, pessoa.Cep, pessoa.Telefone, pessoa.Cpf)

	if err != nil {
		println("Falha ao atualizar pessoa: " + err.Error())
		return nil
	}
	c.JSON(200, pessoa)
	return nil
}
func (p *pessoaController) Post(c echo.Context) error {
	pessoa := new(model.Pessoa)
	err := c.Bind(pessoa)
	if err != nil {
		println("Falha ao dar parse na pessoa: " + err.Error())
		return nil
	}

	_, err = p.conn.Exec("INSERT into pessoa(nome, rua, bairro, cidade, cep, telefone, cpf) values($1, $2, $3, $4, $5, $6, $7)",
		pessoa.Nome, pessoa.Rua, pessoa.Bairro, pessoa.Cidade, pessoa.Cep, pessoa.Telefone, pessoa.Cpf)

	if err != nil {
		println("Falha ao inserir pessoa: " + err.Error())
		return nil
	}
	c.JSON(200, pessoa)
	return nil
}
func (p *pessoaController) Delete(c echo.Context) error {
	cpf := c.Param("cpf")
	if cpf == "" {
		return errors.New("CPF vazio")
	}
	_, err := p.conn.Exec("delete from pessoa where cpf=$1", cpf)
	if err != nil {
		println("Falha ao deletar pessoa: " + err.Error())
		return nil
	}
	c.NoContent(400)
	return nil
}
