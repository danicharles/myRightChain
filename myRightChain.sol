/*
Miembro del Grupo:
Nom: Daniel Charles, NIA: 205698
Nom: Pere Caballero, NIA: 205545
Nom: Ramon Vallés, NIA: 205419 
Nom: Ferran Enguix, NIA: 195659
Nom: María Isabel Lozano, NIA: 196299
Nom: Marta Mir, NIA: 206679
*/

/*
Explicacion:

Con el código, pretendemos que los autores puedan registrar su contenido durante un tiempo pagando una cantidad y dar permiso para que se pueda utilizar en las plataformas que ellos elijan. Por otro lado, los usuarios pueden pagar una cierta cantidad para poder usar un contenido registrado durante un tiempo limitado.
*/

/*
Como hacer el deploy:

Primero tenemos que hacer el deploy del contrato MyRightChainToken.

A continuación debemos hacer el deploy del contrato MyContent y como parámetro añadir la dirección de una wallet para que tu puedas pagar con la cuenta que haces el deploy a la cuenta hayas introducido por parámetro.
Esto sirve para que el autor (persona que hace el deploy), pueda pagar a otra wallet (_paywallet) para colgar su contenido a la blockchain.

Finalmente hacemos el deploy de MyContract, i en este caso los parámetros que introducimos son:
    - _walletToBuyMRC : que será una dirección a la que le haremos una transferencia para comprar MRC a cambio de eth, wei,...
    - _content : que hara referencia a la direccion del deploy que hemos hecho con el contrato MyContent.
    - _token : que hará referencia a la dirección del deploy que hemos hecho con el contrato MyRightChainToken.
*/

/*
Restricciones de uso en el contrato:

Hay algunas restricciones de uso, cuando un usuario desea comprar MRC, este debe introducir algún valor a value.
Pasa exactamente lo mismo cuando el autor quiere registrar un contenido, en este caso el valor debe ser más grande o igual a 20 wei.

Finalmente, el contrato MyContent solo puede modificarlo la persona que ha hecho el deploy y únicamente puede hacerlo durante 15 días una vez se ha hecho el deploy.

Básicamente debemos interactuar con las funciones de MyContent (para el autor) y MyContract (para los compradores).
En el contrato MyRightChainToken podemos ver los MRC tokens de cada cuenta así como el nombre y símbolo de este token.
*/

/*
Ejemplo de uso Basico:
Una vez hemos hehco el deploy correctamente, dentro del deploy de MyContent debemos registrar un contenido con la misma cuenta con la que se ha hecho ese deploy. 
Para ello añadimos un valor superior a 20 wei i llamamos a la funcion registerContent llenando los parametros.

Luego en el deploy de MyContract debemos primero añadir un valor a value mas grande de 0, y llamar a la funcion buyMRC con la cantidad de MRC tokens que deseamos.
A continuacion llamamos a registerPurchaser y llenamos los paramentros que pide, teniendo en cuenta que los _years deben ser mas pequeños o igual a la cantidad de MRC Tokens que la cuenta posee.
*/

pragma solidity 0.5.16;


/*
MyRightChain Token o MRC es la moneda que utilizaremos para comprar los derechos de un contenido
*/
contract MyRightChainToken {
    
    string public name; // Nombre de la moneda
    string public symbol; // Símbolo de la moneda
    mapping(address => uint256) public ownerTokens; // cantidad de MRC que tiene cada address
    
    // En el constructor ponemos los valores por defecto de los atributos name y symbol
    constructor() public {
        name = "MyRightChain Token";
        symbol = "MRC";
    }
    
    /*
    Esta funcion retorna el numero de MRC asociado a la address que ha llamado a la funcion
    */
    function getOwnTokens() public view returns (uint256){
        return ownerTokens[tx.origin];
    }
    
    /*
    La función buyMRC permite a una address comprar una cierta cantidad de MRC Tokens
    */
    function buyMRC(uint256 _amount) public {
       ownerTokens[tx.origin] += _amount;
    }
    
    /*
    La función payMRC permite transferir una cierta cantidad de MRC Tokens de la address que ha llamado a la función a otra address
    */
    function payMRC( address _wallet, uint256 _amount) public{
        ownerTokens[tx.origin] -= _amount;
        ownerTokens[_wallet] += _amount; 
    }
    
}

/*
Mediante este contrato, un autor puede subir su contenido a la Blockchain para posteriormente dar permisos a otros usuarios para usarlo en ciertas plataformas que el autor autorice. 
*/
contract MyContent {
    
    address payable wallet;//La wallet del autor que sube su contenido.
    address payable payForAddContent;//La wallet donde el autor pagará para subir su contenido.

    uint256 daysToModifyContract; // La idea es que un vez el autor registra su contenido, este tiene 15 días para hacer cualquier modificación sobre los permisos o su informacion, una vez terminen los 15 dias ya no se podrán realizar mas cambios.

    /*
    En esta struct se guardará toda la información del autor, en este caso el nombre, el apellido i su alias.
    */
    struct Author{
        string  _firstName;
        string  _surname;
        string _alias;
    }
    
    Author author;
    string referenceToContent; // Con la variable referenceToContent, guardaremos la URL que te dirige al contenido original del autor
    
    /*
    En esta struct estan todas las plataformas a las cuales el autor puede dar permiso para que se suba su contenido
    */
    struct Plataforms {
        bool  _twitter;
        bool  _instagram;
        bool  _facebook;
        bool  _tiktok;
        bool  _youtube;
        bool  _pinterest;
        bool  _ownplataforms;
    }
    Plataforms permissionPlataforms;
    
    /*
    En el constructor, damos valor a las dos wallets tal y como hemos comentado anteriormente y ponemos a false todas las plataformas para que en un principio
    el contenido no se puede subir a ninguna de estas.
    */
    constructor(address payable _paywallet) public{
        wallet = msg.sender; // msg.sender hace referencia a la persona que hace el deploy del contrato
        payForAddContent = _paywallet; // esta wallet es el parámetro que pondremos al hacer el deploy
        
        daysToModifyContract = now + 15 * 24 * 60 * 60; // Fecha límite que el owner tiene para modificar el contrato

        permissionPlataforms._twitter = false;
        permissionPlataforms._instagram = false;
        permissionPlataforms._facebook = false;
        permissionPlataforms._tiktok = false;
        permissionPlataforms._youtube = false;
        permissionPlataforms._pinterest = false;
        permissionPlataforms._ownplataforms = false;
    }
    
    /*
    En la función setAuthor damos valor a todos los atributos del autor (nombre, apellido y alias).
    */
    function setAuthor(string memory _firstName, string memory _surname, string memory _alias) internal onlyOwner(){
        author._firstName = _firstName;
        author._surname = _surname;
        author._alias = _alias;
    }
    
    /*
    En setReferenceToContent añadimos la URL en la cual se encuentra el contenido que queremos subir a la Blockchain
    */
    function setReferenceToContent(string memory _URL) internal onlyOwner() {
        referenceToContent = _URL;
    }
    
    /*
    En la función registerContent, llamamos a las funciones anteriores para realizar todo el proceso completo, añadimos la información del autor, la url donde 
    se encuentra el contenido y realizamos el pago.
    */
    function registerContent(string memory _firstName, string memory _surname, string memory _alias, string memory _URL) public payable onlyOwner() payAmount() onlyWhileOpen() {
        setAuthor(_firstName,_surname,_alias);
        setReferenceToContent(_URL);
        payForAddContent.transfer(msg.value); // para realizar el pago hacemos una transferencia a la cuenta distribuidora del valor que hay en value.
    }
    
    /*
    Este modificador se usa para la función registerContent. Esto obliga al autor a poder realizar la acción únicamente si el valor de msg.value es superior o igual a 20 wei
    */
    modifier payAmount(){
        require(msg.value >= 20);
        _;
    }
    
    /*
    Con este modificador, solo podremos realizar una acción si somos los "owners" del contrato, que en este caso se usara en prácticamente todas las funciones
    */
    modifier onlyOwner(){
        require(wallet == msg.sender);
        _;
    }
    
    modifier onlyWhileOpen() {
        require(block.timestamp <= daysToModifyContract);
        _;
    }
    
    /*
    Este get nos devuelve la address de la wallet del owner del contrato
    */
    function getAuthorWallet() public view returns (address){
        return wallet;
    }
    
    /*
    Con estas funciones obtenemos los getters con informacion del autor, asi como del contenido
    */
    function getAuthorName() public view returns (string memory Name){
        return author._firstName;
    }
    function getAuthorSurname() public view returns (string memory Surname){
        return author._surname;
    }
    function getAuthorAlias() public view returns (string memory Alias){
        return  author._alias;
    }
    function getURL() public view returns (string memory ContentURL){
        return referenceToContent;
    }
    
    
    /*
    Con estas funciones podremos dar permiso para que nuestro contenido pueda ser usado en las plataformas que elijamos
    */
    function addTwitter() public onlyOwner() onlyWhileOpen() {
        permissionPlataforms._twitter = true;
    }
    function addInstagram() public onlyOwner() onlyWhileOpen() {
        permissionPlataforms._instagram = true;
    }
    function addFacebook() public onlyOwner() onlyWhileOpen() {
        permissionPlataforms._facebook = true;
    }
    function addTikTok() public onlyOwner() onlyWhileOpen() {
        permissionPlataforms._tiktok = true;
    }
    function addYoutube() public onlyOwner() onlyWhileOpen() {
        permissionPlataforms._youtube = true;
    }
    function addPinterest() public onlyOwner() onlyWhileOpen() {
        permissionPlataforms._pinterest = true;
    }
    function addOwnPlataforms() public onlyOwner() onlyWhileOpen() {
        permissionPlataforms._ownplataforms = true;
    }
    
     /*
    Con estas funciones podremos denegar los permisos 
    */
    function deleteTwitter() public onlyOwner() onlyWhileOpen() {
        permissionPlataforms._twitter = false;
    }
    function deleteInstagram() public onlyOwner() onlyWhileOpen() {
        permissionPlataforms._instagram = false;
    }
    function deleteFacebook() public onlyOwner() onlyWhileOpen() {
        permissionPlataforms._facebook = false;
    }
    function deleteTikTok() public onlyOwner() onlyWhileOpen() {
        permissionPlataforms._tiktok = false;
    }
    function deleteYoutube() public onlyOwner() onlyWhileOpen() {
        permissionPlataforms._youtube = false;
    }
    function deletePinterest() public onlyOwner() onlyWhileOpen() {
        permissionPlataforms._pinterest = false;
    }
    function deleteOwnPlataforms() public onlyOwner() onlyWhileOpen() {
        permissionPlataforms._ownplataforms = false;
    }
    
    /*
    Con estas funciones podremos ver si el autor ha dado permiso a una plataforma o no
    */
    function permissionsTwitter() public view returns (bool){
        return permissionPlataforms._twitter;
    }
    function permissionsInstagram() public view returns (bool){
        return permissionPlataforms._instagram;
    }
    function permissionsFacebook() public view returns (bool){
        return permissionPlataforms._facebook;
    }
    function permissionsTikTok() public view returns (bool){
        return permissionPlataforms._tiktok;
    }
    function permissionsYoutube() public view returns (bool){
        return permissionPlataforms._youtube;
    }
    function permissionsPinterest() public view returns (bool){
        return permissionPlataforms._pinterest;
    }
    function permissionsOwnPlataforms() public view returns (bool){
        return permissionPlataforms._ownplataforms;
    }
}



/*
Este es el contrato en el que los usuarios podran comprar ciertos derechos a un autor para utilizar su contenido durante un cierto periodo de tiempo.
*/
contract MyContract {

    
    address public content; // dirección que hace referencia al contrato MyContent
    address public MRC; // direccion que hace referencia al contrato MyRightChainToken
    
    uint256 purchaserCount = 0; // número de usuarios que han comprado el contenido del autor

    mapping(uint => Purchaser) public purchasers; // mapeo para guardar la información de cada comprador en un entero
    address payable wallet; // dirección donde el usuario compra los MRC

    // Purchaser es la estructura que contiene la información del comprador del contenido
    struct Purchaser {
        uint256 _id; // el id hará referencia al número de compradores que había antes de que el usuario comprará derechos del contenido
        string  _firstName; // Nombre del comprador
        string  _surname; // Apellido del comprador
        
        /*
        Estos dos atributos van juntos y sirven como registro para saber durante que periodo de tiempo el usuario ha tenido acceso para usar el contenido
        */
        uint256[] _dates; // La fecha en la que se efectuó la compra
        uint256[] _timesToExpire; // Tiempo de validez de la compra en años
        
        /*
        Estos atributos son los mismos que los otros dos, solo que muestran la fecha en la que se hizo la última compra de los derechos y la validez actual de estos.
        */
        uint256 _lastdate;
        uint256 _lastTimeToExpire; 
        
        /*Una vez termine el periodo de validez, si un usuario decide volver a comprar el contenido, los valores de _lastdate i de  _lastTimeToExpire se guardaran dentro de _dates i _timesToExpire respectivamente.
        A continuación se asignarán los nuevos valores  a _lastdate i de  _lastTimeToExpire.
        Si un usuario decide comprar otra vez los derechos mientras está dentro del periodo de validez, solo se modificara el atributo _lastTimeToExpire añadiendo el nuevo periodo adquerido.
        */
    }
    
    
    /*
    En el constructor básicamente inicializamos los atributos que hacen referencia a otras address.
    */
    constructor(address payable _walletToBuyMRC,address _content, address _Token) public {
        content = _content;
        MRC = _Token;
        wallet = _walletToBuyMRC;
    }
    
    /*
    haveEnoughMRC es una funcion auxiliar que nos permitira saber si un usuario tiene los MRC suficientes para comprar los derechos del contenido durante los años que ha seleccionado.
    En este caso como producto minimo viable, hemos decidido que 1 MRC equivale a 1 año de acceso a los derechos del contenido
    */
    function haveEnoughMRC(uint256 _years) internal view  returns(bool){
        MyRightChainToken _token = MyRightChainToken(address(MRC)); // Interaccionamos con el contrato MyRightChainToken
        if(_token.getOwnTokens() >=  _years){ // comprobamos que la cantidad de MRC que tiene el usuario sea mayor o igual al número de años seleccionados
            return true;
        }
        return false;
    }
    
    /*
    addPurchaser es la función que añade a un comprador a la lista de "purchasers".
    */
    function addPurchaser(string memory _firstName, string memory _surname, uint256  _years) internal{
        Purchaser memory pr;
        pr._id = purchaserCount;
        pr._firstName = _firstName;
        pr._surname = _surname;
        pr._lastdate = block.timestamp; // block.timestamp o now coje por defecto al fecha en la que se ejecuta la funcion.
        pr._lastTimeToExpire = _years;
        purchasers[purchaserCount] = pr;
        incrementPurchasers(); // llamamos a esta función para incrementar el número de compradores
    }
    
    /*
    isPurchaserRegistered sirve para identificar a los compradores existentes de los derechos del contenido.
    */
    function isPurchaserRegistered(string memory _firstName, string memory _surname) internal view returns (bool,uint256){
        /*
        Mediante un for loop miramos si existe otro usuario con el mismo nombre y apellido, en el caso de encontrarlo, la función devuelve un booleano (true), junto con la posición donde ha encontrado a dicho usuario.
        */
        for (uint256 i = 0; i < purchaserCount; i++) {
            if((keccak256(bytes(purchasers[i]._firstName)) == keccak256(bytes(_firstName))) && (keccak256(bytes(purchasers[i]._surname)) == keccak256(bytes(_surname)))){
                return (true, i);
            }
        }
        /*
        Si una vez recorrido todo el loop no encuentra al usuario retorna false, junto a un valor cualquiera, ya que este no será usado
        */
        return (false, 0);
    }

    /*
    Con registerPurchaser es con la función que el usuario interactuara para comprar los derechos del contenido
    */
    function registerPurchaser( string memory _firstName, string memory _surname, uint256  _years) public{
        /*
        En primer lugar, comprobamos que dicho comprador tiene el dinero suficiente para realizar la compra de los derechos durante el tiempo que el ha seleccionado.
        Para ello haremos uso de la función haveEnoughMRC.
        */
        if(haveEnoughMRC(_years)){
            
            /*
            Con la llamada a esta función, sabremos si el usuario ya ha comprado contenidos anteriormente gracias a la variable b, que contendrá true en caso de que exista i false en caso que no exista.
            La variable pos, por otro lado contendrá la posición en la que se encuentra el comprador, en caso de que este exista.
            */
            (bool b,uint256 pos) = isPurchaserRegistered(_firstName,_surname); 

            uint256 t = purchasers[pos]._lastdate + purchasers[pos]._lastTimeToExpire * 365 * 24 * 60 * 60; // la variable t contendrá la fecha en la que los derechos del usuario terminan
            
            if(b){ // si existe el usuario como comprador
                /*
                Comprobamos si el usuario actualmente sigue teniendo los derechos de autor.
                Si t (fecha en la que expiran sus derechos) es menor a la fecha actual en la que se ejecuta el contrato (block.timestamp) significa sus derechos han expirado,
                por tanto al comprar los derechos de nuevo, debemos guardar los antigos en un registro y añadir las nuevas fechas que ha adquirido el comprador.
                */
                if( t < block.timestamp){ 
                    
                    /*
                    Guardamos las posiciones antiguas en el registro
                    */
                    purchasers[pos]._timesToExpire.push(purchasers[pos]._lastTimeToExpire);
                    purchasers[pos]._dates.push(purchasers[pos]._lastdate);
                    
                    /*
                    Actualizamos las variables actuales
                    */
                    purchasers[pos]._lastdate = now; // now is a synonym of block.timestamp
                    purchasers[pos]._lastTimeToExpire = _years;
                    
                    /*
                    Finalmente llamamos a la función pay, para que el usuario pague al autor por sus derechos.
                    */
                    pay(_years);
                }
                /*
                En el caso que los derechos aun sean validos, únicamente hemos de aumentar la cifra de años por los que el usuario posee los derechos, y realizar el pago
                */
                else{
                    purchasers[pos]._lastTimeToExpire += _years;
                    pay(_years);
                }
            }
            /*
            Finalmente si el usuario no existe, básicamente llamamos a la función addPurchaser para crearlo y realizamos el pago. 
            */
            else{
                addPurchaser(_firstName, _surname, _years);
                pay(_years);
            }
        }
    }
    
    /*
    incrementPurchasers es una función interna para aumentar el número de compradores cada vez que hay uno nuevo.
    */
    function incrementPurchasers() internal {
        purchaserCount ++;
    }

    /*
    La función pay permite al comprador pagar al autor por sus derechos
    */
    function pay(uint256 _years)public payable {
        MyRightChainToken _token = MyRightChainToken(address(MRC)); // Interaccionamos con el contrato MyRightChainToken para poder llamar a la función payMRC
        MyContent _content = MyContent(address(content)); // Interaccionamos con el contrato MyContent para obtener la wallet del autor del contenido
       _token.payMRC(_content.getAuthorWallet(), _years); // con la llamada a payMRC dentro del contrato de MyRightChainToken, con la address del autor y la cantidad, lo que haremos es transferir de nuestra cuenta la cantidad establecida a la del autor
    }
    
    /*
    Esta es una función auxiliar para restringir la función buyMRC, en este caso aún no se ha establecido un precio, pero forzamos al usuario a que si desea comprar una cantidad concreta de MRC deba transferir una cierta cantidad de dinero a la cuenta distribuidora.
    Es decir, debemos poner una cantidad superior a 0 en value para poder comprar los MRC Tokens.
    */
    modifier paySomething() {
        require(msg.value > 0);
        _;
    }
    
    /*
    Con esta función podremos comprar una cierta cantidad de MRC Tokens a la cuenta que indiquemos en el constructor.
    */
    function buyMRC(uint256 _amount) public payable paySomething() {
        MyRightChainToken _token = MyRightChainToken(address(MRC)); // Interaccionamos con el contrato MyRightChainToken
        _token.buyMRC(_amount); // llamamos a la funcion buyMRC que se encuentra dentro del contrato MyRightChainToken
        wallet.transfer(msg.value); // realizamos una transferencia al distribuidor de MRC Tokens con el valor que tengamos en value
    }
    
}





