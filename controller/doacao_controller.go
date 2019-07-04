package controller

import (
	"errors"
	"projeto_bd/model"

	"github.com/jmoiron/sqlx"
	"github.com/labstack/echo"
	_ "github.com/lib/pq"
)

type DoacaoController struct {
	conn *sqlx.DB
}

func NewDoacaoController() *DoacaoController {
	p := new(DoacaoController)
	var err error
	p.conn, err = sqlx.Connect("postgres", "postgres://root@localhost:5432/trabalho?sslmode=disable")
	if err != nil {
		println("Falha ao conectar: " + err.Error())
		return nil
	}
	return p
}
func (p *DoacaoController) Get(c echo.Context) error {
	codigo := c.Param("codigo")
	if codigo == "" {
		doacoes := []model.Doacao{}
		err := p.conn.Select(&doacoes, "select * from doacao")
		if err != nil {
			println("Falha ao buscar doacao: " + err.Error())
			return err
		}
		return c.JSON(200, doacoes)

	} else {
		doacao := model.Doacao{}
		err := p.conn.Get(&doacao, "select * from doacao where codigo = $1", codigo)
		if err != nil {
			println("Falha ao buscar doacao: " + err.Error())
			return err
		}
		return c.JSON(200, doacao)
	}
}
func (p *DoacaoController) Put(c echo.Context) error {

	doacao := new(model.Doacao)
	err := c.Bind(doacao)
	if err != nil {
		println("Falha ao dar parse na doacao: " + err.Error())
		return err
	}

	_, err = p.conn.Exec("UPDATE doacao"+
		"set cpf_pessoa = $1,"+
		"codigo_ong = $2,"+
		"tipo = $3,"+
		"valor = $4,"+
		"data = $5,"+
		"where codigo=$6",
		doacao.CpfPessoa, doacao.CodigoOng, doacao.Tipo, doacao.Valor, doacao.Data, doacao.Codigo)

	if err != nil {
		println("Falha ao atualizar doacao: " + err.Error())
		return nil
	}
	return nil
}
func (p *DoacaoController) Post(c echo.Context) error {
	doacao := new(model.Doacao)
	err := c.Bind(doacao)
	if err != nil {
		return err
	}
	_, err = p.conn.Exec("INSERT into doacao(cpf_pessoa, codigo_ong, tipo, valor, data) values($1, $2, $3, $4, $5)", doacao.CpfPessoa, doacao.CodigoOng, doacao.Tipo, doacao.Valor, doacao.Data)
	if err != nil {
		println("Falha ao inserir doacao: " + err.Error())
		return err
	}
	c.NoContent(400)
	return nil
}
func (p *DoacaoController) Delete(c echo.Context) error {
	codigo := c.Param("codigo")
	if codigo == "" {
		return errors.New("Codigo vazio")
	}
	_, err := p.conn.Exec("delete from doacao where codigo=$1", codigo)
	if err != nil {
		println("Falha ao deletar doacao: " + err.Error())
		return err
	}
	c.NoContent(400)
	return nil
}
